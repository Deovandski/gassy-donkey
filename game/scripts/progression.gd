class_name Progression
## Levels, stat points and what the stats do, from data/progression.json.
## Pure functions, so the tests can check them without a running game.


## The level for a total amount of XP (1 to the last level in xp_to_reach).
static func level_for_xp(xp: int, table: Array) -> int:
	var level := 1
	for i in range(1, table.size()):
		if xp >= int(table[i]):
			level = i + 1
	return level


static func max_level(table: Array) -> int:
	return table.size()


## XP into the current level and XP the level needs, for the XP bar. At the top level: [0, 0].
static func level_progress(xp: int, table: Array) -> Vector2i:
	var level := level_for_xp(xp, table)
	if level >= table.size():
		return Vector2i(0, 0)
	var start := int(table[level - 1])
	return Vector2i(xp - start, int(table[level]) - start)


## Points to spend: one per level after the first, minus what the stats already used.
static func free_points(level: int, stats: Dictionary, stat_min: int) -> int:
	var spent := 0
	for key in stats:
		spent += int(stats[key]) - stat_min
	return maxi(0, (level - 1) - spent)


static func hearts(stats: Dictionary, p: Dictionary) -> int:
	var s: Dictionary = p["stats"]["health"]
	return int(s["hearts_base"]) + int(s["hearts_per_rank"]) * int(stats.get("health", 1))


## How much faster a fart pushes the donkey (a speed multiplier).
static func fart_boost(stats: Dictionary, p: Dictionary) -> float:
	var s: Dictionary = p["stats"]["fart"]
	return float(s["boost_base"]) + float(s["boost_per_rank"]) * (int(stats.get("fart", 1)) - 1)


## How far behind the donkey a fart scares things away (pixels).
static func fart_radius(stats: Dictionary, p: Dictionary) -> float:
	var s: Dictionary = p["stats"]["fart"]
	return float(s["radius_base"]) + float(s["radius_per_rank"]) * (int(stats.get("fart", 1)) - 1)


## Jump speed multiplier from jump power.
static func jump_factor(stats: Dictionary, p: Dictionary) -> float:
	return 1.0 + float(p["stats"]["jump"]["jump_per_rank"]) * (int(stats.get("jump", 1)) - 1)


static func headbutt_reach(stats: Dictionary, p: Dictionary) -> float:
	var s: Dictionary = p["stats"]["headbutt"]
	return float(s["reach_base"]) + float(s["reach_per_rank"]) * (int(stats.get("headbutt", 1)) - 1)


## A headbutt breaks a thing when headbutt power is at least the thing's hp (hp 0: unbreakable).
static func headbutt_breaks(stats: Dictionary, hp: int) -> bool:
	return hp > 0 and int(stats.get("headbutt", 1)) >= hp


## 2016 design: "the player would need farting at least on level 2 in order to scare the tiger away".
static func scares_tiger(stats: Dictionary) -> bool:
	return int(stats.get("fart", 1)) >= 2


## Run speed multiplier after `metres`: x step_factor every step_every_m, capped (2016 sketch: "x1.2 every 200 m").
static func speed_factor(metres: float, speed: Dictionary) -> float:
	var steps := floori(metres / float(speed["step_every_m"]))
	return minf(pow(float(speed["step_factor"]), steps), float(speed["max_factor"]))


static func speed_level(metres: float, speed: Dictionary) -> int:
	return floori(metres / float(speed["step_every_m"])) + 1
