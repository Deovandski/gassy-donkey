extends Node
## Keeps the player's progress in user://save.json (IndexedDB in browsers, app storage on Android).
##
## The format is documented in docs/SAVE_FORMAT.md. Bump VERSION, add a step to _migrate(), update the doc
## and the tests whenever the format changes.

signal changed
signal achievement_unlocked(id: String)
signal leveled_up(level: int)

const FORMAT := "gassy-donkey-save"
const VERSION := 1
const COUNTERS := ["farts", "super_farts", "mosquitoes", "tigers", "bears", "cowboys", "enemies", "corn", "distance_m", "runs", "stages_finished"]

var save_path := "user://save.json"
var data: Dictionary = {}
## Set false by the tests so nothing is written to disk.
var autosave := true


func _ready() -> void:
	load_local()


static func default_data() -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	var counters := {}
	for c in COUNTERS:
		counters[c] = 0
	return {
		"format": FORMAT,
		"version": VERSION,
		"created_at": now,
		"updated_at": now,
		"xp": 0,
		"stats": {"health": 1, "fart": 1, "jump": 1, "headbutt": 1},
		# Per stage id: {"done": bool, "best_m": int, "best_gas": int, "all_gas": bool, "no_hit": bool}
		"stages": {},
		# Per achievement id: the date it was unlocked (YYYY-MM-DD).
		"achievements": {},
		"counters": counters,
		"settings": {"music": 0.7, "sfx": 1.0, "touch_buttons": true},
	}


# --------------------------------------------------------------------------------------------- disk

func load_local() -> void:
	data = default_data()
	if not FileAccess.file_exists(save_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(parsed) == TYPE_DICTIONARY and parsed.get("format", "") == FORMAT:
		apply(parsed)


func save_local() -> void:
	data["updated_at"] = Time.get_datetime_string_from_system(true)
	if not autosave:
		return
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: can't write %s" % save_path)
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()


## Applies a parsed save (from disk or a test): migrates it, fills in anything missing.
func apply(parsed: Dictionary) -> bool:
	var version := int(parsed.get("version", 0))
	if version < 1 or version > VERSION:
		return false
	data = _merge_defaults(_migrate(parsed, version), default_data())
	data["version"] = VERSION
	changed.emit()
	return true


## Upgrades older saves one version at a time. (Version 1 is the first; nothing to do yet.)
func _migrate(save: Dictionary, _from_version: int) -> Dictionary:
	return save.duplicate(true)


static func _merge_defaults(save: Dictionary, defaults: Dictionary) -> Dictionary:
	var out := save.duplicate(true)
	for key in defaults:
		if not out.has(key) or typeof(out[key]) != typeof(defaults[key]):
			out[key] = defaults[key]
		elif typeof(defaults[key]) == TYPE_DICTIONARY and key != "stages" and key != "achievements":
			out[key] = _merge_defaults(out[key], defaults[key])
	return out


func reset() -> void:
	var settings: Dictionary = data.get("settings", {}).duplicate()
	data = default_data()
	data["settings"] = _merge_defaults(settings, data["settings"])
	save_local()
	changed.emit()


# --------------------------------------------------------------------------------------------- progress

func xp_table() -> Array:
	return GameData.progression.get("xp_to_reach", [0])


func level() -> int:
	return Progression.level_for_xp(int(data["xp"]), xp_table())


func stats() -> Dictionary:
	return data["stats"]


func free_points() -> int:
	return Progression.free_points(level(), stats(), int(GameData.progression.get("stat_min", 1)))


## Spends a point on a stat. Returns false when there are no points or the stat is full.
func raise_stat(stat: String) -> bool:
	if free_points() <= 0 or not stats().has(stat):
		return false
	if int(stats()[stat]) >= int(GameData.progression.get("stat_max", 5)):
		return false
	stats()[stat] = int(stats()[stat]) + 1
	check_achievements()
	save_local()
	changed.emit()
	return true


## Adds XP. Returns how many levels were gained.
func add_xp(amount: int) -> int:
	var before := level()
	data["xp"] = int(data["xp"]) + maxi(0, amount)
	var after := level()
	if after > before:
		leveled_up.emit(after)
	check_achievements()
	return after - before


func count(counter: String, amount: int = 1) -> void:
	var c: Dictionary = data["counters"]
	c[counter] = int(c.get(counter, 0)) + amount
	check_achievements()


func stage_record(stage_id: String) -> Dictionary:
	return data["stages"].get(stage_id, {})


func is_stage_done(stage_id: String) -> bool:
	return bool(stage_record(stage_id).get("done", false))


## A stage can be played once the one before it is finished (World 1 stage 1 is always open).
func is_stage_open(stage_id: String) -> bool:
	var ids := GameData.all_stage_ids()
	var i := ids.find(stage_id)
	return i == 0 or (i > 0 and is_stage_done(ids[i - 1]))


func is_world_open(world_id: String) -> bool:
	var w := GameData.world(world_id)
	return not w.is_empty() and is_stage_open(w["stages"][0]["id"])


## Records a finished (or failed) run and saves.
func record_run(stage_id: String, metres: int, gas: int, gas_total: int, finished: bool, hit: bool) -> void:
	var r: Dictionary = data["stages"].get(stage_id, {"done": false, "best_m": 0, "best_gas": 0, "all_gas": false, "no_hit": false})
	r["best_m"] = maxi(int(r.get("best_m", 0)), metres)
	r["best_gas"] = maxi(int(r.get("best_gas", 0)), gas)
	if finished:
		r["done"] = true
		if gas >= gas_total and gas_total > 0:
			r["all_gas"] = true
		if not hit:
			r["no_hit"] = true
	data["stages"][stage_id] = r
	count("runs")
	if finished:
		count("stages_finished")
	if finished and gas >= gas_total and gas_total > 0:
		unlock("all_corn")
	if finished and not hit:
		unlock("untouchable")
	for w in GameData.world_list():
		var all_done := true
		for s in w["stages"]:
			all_done = all_done and is_stage_done(s["id"])
		if all_done:
			unlock(w["id"] + "_done")
	save_local()
	changed.emit()


# --------------------------------------------------------------------------------------------- achievements

func is_unlocked(id: String) -> bool:
	return data["achievements"].has(id)


func unlock(id: String) -> void:
	if is_unlocked(id) or GameData.achievement(id).is_empty():
		return
	data["achievements"][id] = Time.get_date_string_from_system()
	achievement_unlocked.emit(id)


## Progress towards an achievement with a counter: [have, goal]. Without a counter: [0 or 1, 1].
func achievement_progress(a: Dictionary) -> Vector2i:
	var goal := int(a.get("goal", 1))
	if is_unlocked(a["id"]):
		return Vector2i(goal, goal)
	if not a.has("counter"):
		return Vector2i(1 if is_unlocked(a["id"]) else 0, 1)
	var have := level() if a["counter"] == "level" else int(data["counters"].get(a["counter"], 0))
	if a["id"] == "level_max":
		var full := true
		for s in stats():
			full = full and int(stats()[s]) >= int(GameData.progression.get("stat_max", 5))
		if not full:
			have = mini(have, goal - 1)
	return Vector2i(mini(have, goal), goal)


func check_achievements() -> void:
	for a in GameData.achievements:
		if a.has("counter") and not is_unlocked(a["id"]):
			var p := achievement_progress(a)
			if p.x >= p.y:
				unlock(a["id"])


func setting(key: String):
	return data["settings"].get(key)


func set_setting(key: String, value) -> void:
	data["settings"][key] = value
	save_local()
	changed.emit()
