extends TestSuite
## The save format (docs/SAVE_FORMAT.md) and the progress rules in SaveManager.


func _fresh() -> void:
	SaveManager.autosave = false
	SaveManager.data = SaveManager.default_data()


func test_default_save() -> void:
	var d := SaveManager.default_data()
	check_eq(d["format"], SaveManager.FORMAT, "format")
	check_eq(d["version"], SaveManager.VERSION, "version")
	check_eq(d["xp"], 0, "xp")
	for stat in ["health", "fart", "jump", "headbutt"]:
		check_eq(d["stats"][stat], 1, "%s starts at 1" % stat)
	for c in SaveManager.COUNTERS:
		check(d["counters"].has(c), "counter %s" % c)


func test_apply_fills_missing_keys_and_rejects_bad_versions() -> void:
	_fresh()
	check(SaveManager.apply({"format": SaveManager.FORMAT, "version": 1, "xp": 300}), "applies a version 1 save")
	check_eq(SaveManager.data["xp"], 300, "keeps xp")
	check(SaveManager.data.has("settings") and SaveManager.data["settings"].has("music"), "fills in settings")
	check(not SaveManager.apply({"format": SaveManager.FORMAT, "version": SaveManager.VERSION + 1}), "rejects a newer save")
	check(not SaveManager.apply({"format": SaveManager.FORMAT}), "rejects a save with no version")


func test_points_and_stats() -> void:
	_fresh()
	check(not SaveManager.raise_stat("fart"), "no points at level 1")
	SaveManager.add_xp(250)  # level 3
	check_eq(SaveManager.level(), 3, "level 3")
	check_eq(SaveManager.free_points(), 2, "2 points")
	check(SaveManager.raise_stat("fart"), "spend one")
	check_eq(SaveManager.stats()["fart"], 2, "fart 2")
	check_eq(SaveManager.free_points(), 1, "1 point left")
	check(not SaveManager.raise_stat("charisma"), "unknown stat")


func test_stages_open_in_order() -> void:
	_fresh()
	var ids := GameData.all_stage_ids()
	check(SaveManager.is_stage_open(ids[0]), "the first stage is open")
	check(not SaveManager.is_stage_open(ids[1]), "the second is locked")
	check(not SaveManager.is_world_open("desert"), "World 2 is locked")
	SaveManager.record_run(ids[0], 100, 2, 12, false, true)
	check(not SaveManager.is_stage_open(ids[1]), "a failed run doesn't open the next stage")
	SaveManager.record_run(ids[0], 450, 12, 12, true, false)
	check(SaveManager.is_stage_open(ids[1]), "finishing opens the next stage")
	check(SaveManager.is_unlocked("all_corn"), "all gas items: Corn Collector")
	check(SaveManager.is_unlocked("untouchable"), "no hit: Untouchable")
	check_eq(SaveManager.stage_record(ids[0])["best_m"], 450, "best distance")
	for id in ids:
		if id.begins_with("amazon"):
			SaveManager.record_run(id, 1000, 0, 10, true, true)
	check(SaveManager.is_unlocked("amazon_done"), "World 1 done")
	check(SaveManager.is_world_open("desert"), "World 2 open")


func test_counter_achievements() -> void:
	_fresh()
	SaveManager.count("farts")
	check(SaveManager.is_unlocked("first_fart"), "First Toot")
	SaveManager.count("mosquitoes", 24)
	check(not SaveManager.is_unlocked("swatter"), "not yet")
	SaveManager.count("mosquitoes")
	check(SaveManager.is_unlocked("swatter"), "Mosquito Swatter at 25")
	var a := GameData.achievement("swatter")
	check_eq(SaveManager.achievement_progress(a), Vector2i(25, 25), "progress")


func test_every_achievement_has_a_way_to_unlock() -> void:
	var by_code := ["all_corn", "untouchable", "amazon_done", "desert_done"]
	for a in GameData.achievements:
		check(a.has("counter") or a["id"] in by_code, "%s can be unlocked" % a["id"])
		if a.has("counter") and a["counter"] != "level":
			check(a["counter"] in SaveManager.COUNTERS, "%s counter %s exists" % [a["id"], a["counter"]])
	for w in GameData.world_list():
		check(not GameData.achievement(w["id"] + "_done").is_empty(), "achievement for finishing %s" % w["id"])
