extends TestSuite
## Levels, points and stats (scripts/progression.gd with data/progression.json).


func _p() -> Dictionary:
	return GameData.progression


func test_levels_follow_the_table() -> void:
	var table: Array = _p()["xp_to_reach"]
	check_eq(Progression.level_for_xp(0, table), 1, "0 XP")
	check_eq(Progression.level_for_xp(99, table), 1, "99 XP")
	check_eq(Progression.level_for_xp(100, table), 2, "100 XP")
	check_eq(Progression.level_for_xp(999999, table), table.size(), "lots of XP is the top level")
	for i in range(1, table.size()):
		check(int(table[i]) > int(table[i - 1]), "XP table rises at %d" % i)


func test_one_point_per_level_fills_every_stat_at_the_top() -> void:
	var table: Array = _p()["xp_to_reach"]
	var stat_min := int(_p()["stat_min"])
	var stat_max := int(_p()["stat_max"])
	var stats := {"health": 1, "fart": 1, "jump": 1, "headbutt": 1}
	check_eq(Progression.free_points(1, stats, stat_min), 0, "no points at level 1")
	check_eq(Progression.free_points(4, stats, stat_min), 3, "3 points at level 4")
	check_eq(Progression.free_points(4, {"health": 2, "fart": 2, "jump": 1, "headbutt": 1}, stat_min), 1, "spent points count")
	check_eq(Progression.max_level(table) - 1, stats.size() * (stat_max - stat_min), "the top level gives exactly enough points to fill every stat")


func test_stats_change_the_donkey() -> void:
	var low := {"health": 1, "fart": 1, "jump": 1, "headbutt": 1}
	var high := {"health": 5, "fart": 5, "jump": 5, "headbutt": 5}
	check(Progression.hearts(high, _p()) > Progression.hearts(low, _p()), "health adds hearts")
	check(Progression.fart_boost(high, _p()) > Progression.fart_boost(low, _p()), "fart power adds boost")
	check(Progression.fart_radius(high, _p()) > Progression.fart_radius(low, _p()), "fart power adds reach")
	check(Progression.jump_factor(high, _p()) > Progression.jump_factor(low, _p()), "jump power jumps higher")
	check_eq(Progression.jump_factor(low, _p()), 1.0, "rank 1 jump is the base jump")


func test_2016_rules() -> void:
	# "the player would need farting at least on level 2 in order to scare the tiger away"
	check(not Progression.scares_tiger({"fart": 1}), "fart 1 doesn't scare a tiger")
	check(Progression.scares_tiger({"fart": 2}), "fart 2 scares a tiger")
	# headbutt power vs toughness
	check(Progression.headbutt_breaks({"headbutt": 1}, 1), "rank 1 breaks a rock")
	check(not Progression.headbutt_breaks({"headbutt": 1}, 2), "rank 1 doesn't break a cactus")
	check(not Progression.headbutt_breaks({"headbutt": 5}, 0), "hp 0 is never broken")
	# "Speed x1.2 every 200 m", capped
	var speed: Dictionary = GameData.worlds["speed"]
	check_eq(Progression.speed_factor(0, speed), 1.0, "speed at the start")
	check(is_equal_approx(Progression.speed_factor(200, speed), 1.2), "x1.2 after 200 m")
	check(is_equal_approx(Progression.speed_factor(399, speed), 1.2), "still x1.2 at 399 m")
	check(is_equal_approx(Progression.speed_factor(5000, speed), float(speed["max_factor"])), "capped")
