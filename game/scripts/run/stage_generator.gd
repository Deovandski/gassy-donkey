class_name StageGenerator
## Builds a stage's layout from its settings in data/worlds.json and its seed. The same seed always gives
## the same stage, so stages can be learned and the tests can check them.
##
## Layout (all x in pixels from the start, y in pixels from the top of the screen):
##   length: the finish line's x
##   ground: [{x0, x1, water}]  the floor, in pieces; water pieces slow the donkey down (2016 idea:
##           "water levels ... to allow multiple paths")
##   platforms: [{x0, x1, tier}]  tier 1 and 2 levels above the floor (double jump to go up, swipe down to drop)
##   things: [{type, x, tier}]  obstacles and enemies from the stage's "things" counts
##   gas: [{x, y}]  corn or beans, exactly "gas_items" of them
##   tigers: [x]  where a tiger waits on the floor (2016: jump over it, then fart it away)
##   mosquitoes: [x]  where a mosquito starts chasing (2014: it "follows the donkey when not running")

const PX_PER_M := 40.0
const FLOOR_Y := 610.0
## Top of each level: floor, tier 1, tier 2.
const TIER_Y := [610.0, 440.0, 280.0]
const START_CLEAR := 700.0
const END_CLEAR := 500.0
const MIN_THING_GAP := 330.0
const TIGER_CLEAR := 1100.0


static func generate(stage: Dictionary, things_data: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(stage.get("seed", 1))
	var length := float(stage["length_m"]) * PX_PER_M
	var layout := {"length": length, "ground": [], "platforms": [], "things": [], "gas": [], "tigers": [], "mosquitoes": []}

	# Tigers and mosquitoes at fixed shares of the stage, nudged by the seed.
	var tigers := int(stage.get("tigers", 0))
	for i in tigers:
		var share := 0.5 if tigers == 1 else 0.35 + 0.45 * i / float(tigers - 1)
		layout["tigers"].append(roundf(length * share + rng.randf_range(-200, 200)))
	var mosquitoes := int(stage.get("mosquitoes", 0))
	for i in mosquitoes:
		layout["mosquitoes"].append(roundf(length * (0.2 + 0.7 * (i + 0.5) / mosquitoes) + rng.randf_range(-150, 150)))

	# Floor with water pools (never right before a tiger, which needs dry floor to chase on).
	var x := -1400.0
	var water_chance := float(stage.get("water_chance", 0.0))
	while x < length + 1400:
		var run := rng.randf_range(900, 1700)
		layout["ground"].append({"x0": x, "x1": x + run, "water": false})
		x += run
		if x > START_CLEAR + 400 and x < length - END_CLEAR - 600 and rng.randf() < water_chance and not _near_tiger(layout, x, 500):
			var pool := rng.randf_range(260, 520)
			layout["ground"].append({"x0": x, "x1": x + pool, "water": true})
			x += pool

	# Platforms: tier 1 runs, sometimes with a shorter tier 2 run above.
	x = START_CLEAR + rng.randf_range(100, 400)
	var platform_chance := float(stage.get("platform_chance", 0.0))
	while x < length - END_CLEAR - 600:
		if rng.randf() < platform_chance:
			var w := rng.randf_range(520, 1100)
			layout["platforms"].append({"x0": x, "x1": x + w, "tier": 1})
			if w > 700 and rng.randf() < 0.45:
				var w2 := rng.randf_range(300, w - 300)
				var x2 := x + rng.randf_range(150, w - w2)
				layout["platforms"].append({"x0": x2, "x1": x2 + w2, "tier": 2})
			x += w + rng.randf_range(350, 750)
		else:
			x += rng.randf_range(400, 800)

	# Things: shuffled, spread evenly with some jitter, kept out of the water and away from tigers.
	var bag: Array[String] = []
	var counts: Dictionary = stage.get("things", {})
	for type in counts:
		for i in int(counts[type]):
			bag.append(type)
	_shuffle(bag, rng)
	var usable_start := START_CLEAR + 200
	var usable := length - END_CLEAR - usable_start
	var spacing := usable / maxf(1, bag.size())
	var last_x := -INF
	for i in bag.size():
		var type := bag[i]
		var tx := usable_start + spacing * (i + 0.5) + rng.randf_range(-0.25, 0.25) * spacing
		tx = _dry_x(layout, tx, float(things_data.get(type, {}).get("w", 80)))
		if tx - last_x < MIN_THING_GAP:
			tx = last_x + MIN_THING_GAP
		if tx > length - END_CLEAR or _near_tiger(layout, tx, TIGER_CLEAR) or _in_water(layout, tx, 120):
			continue
		var tier := 0
		var over := _platform_over(layout, tx, 1)
		if type == "hive" and over:
			type = "rock_small"  # a hive needs open sky above the floor
		elif over and (type == "snake" or type == "rattlesnake" or type == "rock_small") and rng.randf() < 0.35:
			tier = 1
		layout["things"].append({"type": type, "x": roundf(tx), "tier": tier})
		last_x = tx

	# Gas items: rows along the floor between things, rows on platforms, and arcs over things.
	var want := int(stage.get("gas_items", 0))
	var spots: Array = []
	for p in layout["platforms"]:
		var y: float = TIER_Y[int(p["tier"])] - 60.0
		var n := clampi(int((p["x1"] - p["x0"]) / 260.0), 1, 3)
		var cx: float = (p["x0"] + p["x1"]) / 2.0
		for k in n:
			spots.append({"x": roundf(cx + (k - (n - 1) / 2.0) * 90.0), "y": y, "pref": 2})
	for t in layout["things"]:
		if int(t["tier"]) == 0 and t["type"] != "hive":
			spots.append({"x": t["x"], "y": FLOOR_Y - 190.0, "pref": 1})
	var gx := START_CLEAR - 300
	while gx < length - END_CLEAR:
		if not _thing_near(layout, gx, 160) and not _in_water(layout, gx, 0):
			spots.append({"x": roundf(gx), "y": FLOOR_Y - 55.0, "pref": 0})
		gx += 260
	# A mix: about 40% on platforms (the reward for the high path), 30% over things, 30% on the floor;
	# any share that runs short is filled from the others.
	_shuffle(spots, rng)
	var by_pref := {0: [], 1: [], 2: []}
	for spot in spots:
		by_pref[spot["pref"]].append(spot)
	var take: Array = []
	var shares := {2: roundi(want * 0.4), 1: roundi(want * 0.3)}
	shares[0] = want - shares[2] - shares[1]
	for pref in [2, 1, 0]:
		take.append_array(by_pref[pref].slice(0, shares[pref]))
	var rest: Array = []
	for pref in [0, 1, 2]:
		rest.append_array(by_pref[pref].slice(shares[pref]))
	take.append_array(rest.slice(0, maxi(0, want - take.size())))
	take.sort_custom(func(a, b): return a["x"] < b["x"])
	for s in take:
		layout["gas"].append({"x": s["x"], "y": s["y"]})
	return layout


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _near_tiger(layout: Dictionary, x: float, after: float) -> bool:
	for t in layout["tigers"]:
		if x > t - 500 and x < t + after:
			return true
	return false


static func _in_water(layout: Dictionary, x: float, margin: float) -> bool:
	for g in layout["ground"]:
		if g["water"] and x > g["x0"] - margin and x < g["x1"] + margin:
			return true
	return false


## Moves x past any water it lands in.
static func _dry_x(layout: Dictionary, x: float, w: float) -> float:
	for g in layout["ground"]:
		if g["water"] and x + w / 2 > g["x0"] - 120 and x - w / 2 < g["x1"] + 120:
			return g["x1"] + 120 + w / 2
	return x


static func _platform_over(layout: Dictionary, x: float, tier: int) -> bool:
	for p in layout["platforms"]:
		if int(p["tier"]) == tier and x > p["x0"] - 60 and x < p["x1"] + 60:
			return true
	return false


static func _thing_near(layout: Dictionary, x: float, margin: float) -> bool:
	for t in layout["things"]:
		if absf(t["x"] - x) < margin:
			return true
	for t in layout["tigers"]:
		if absf(t - x) < margin + 100:
			return true
	return false


## The floor height at x: water sits a little lower (the donkey wades).
static func floor_at(layout: Dictionary, x: float) -> Dictionary:
	for g in layout["ground"]:
		if x >= g["x0"] and x < g["x1"]:
			return {"y": FLOOR_Y + (22.0 if g["water"] else 0.0), "water": g["water"]}
	return {"y": FLOOR_Y, "water": false}
