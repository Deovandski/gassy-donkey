extends Node
## Reads the game's data files once (game/data/*.json). Data, not code: worlds, stages, obstacles,
## progression and achievements are all tuned there.

var worlds: Dictionary = {}
var progression: Dictionary = {}
var achievements: Array = []
var credits: Dictionary = {}


func _ready() -> void:
	worlds = load_json("res://data/worlds.json")
	progression = load_json("res://data/progression.json")
	achievements = load_json("res://data/achievements.json").get("achievements", [])
	credits = load_json("res://data/credits.json")


static func load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameData: can't read %s" % path)
		return {}
	return parsed


func world_list() -> Array:
	return worlds.get("worlds", [])


func world(id: String) -> Dictionary:
	for w in world_list():
		if w["id"] == id:
			return w
	return {}


func stage(id: String) -> Dictionary:
	for w in world_list():
		for s in w["stages"]:
			if s["id"] == id:
				return s
	return {}


func world_of_stage(id: String) -> Dictionary:
	for w in world_list():
		for s in w["stages"]:
			if s["id"] == id:
				return w
	return {}


func thing(type: String) -> Dictionary:
	return worlds.get("things", {}).get(type, {})


func achievement(id: String) -> Dictionary:
	for a in achievements:
		if a["id"] == id:
			return a
	return {}


## Every stage in order (World 1 stage 1 first).
func all_stage_ids() -> Array:
	var out := []
	for w in world_list():
		for s in w["stages"]:
			out.append(s["id"])
	return out
