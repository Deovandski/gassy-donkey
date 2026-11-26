extends TestSuite
## Every stage in data/worlds.json builds the same way every time and can be finished at rank 1.

const Run := preload("res://scripts/run/run.gd")


func _stages() -> Array:
	var out := []
	for w in GameData.world_list():
		for s in w["stages"]:
			out.append(s)
	return out


func _things() -> Dictionary:
	return GameData.worlds["things"]


func test_same_seed_same_stage() -> void:
	for s in _stages():
		var a := StageGenerator.generate(s, _things())
		var b := StageGenerator.generate(s, _things())
		check_eq(JSON.stringify(a), JSON.stringify(b), "%s is the same twice" % s["id"])


func test_exact_gas_items_and_things_inside_the_stage() -> void:
	for s in _stages():
		var l := StageGenerator.generate(s, _things())
		check_eq(l["gas"].size(), int(s["gas_items"]), "%s gas items" % s["id"])
		var wanted := 0
		for k in s["things"]:
			wanted += int(s["things"][k])
		check(l["things"].size() >= wanted * 0.7, "%s keeps most of its %d things (got %d)" % [s["id"], wanted, l["things"].size()])
		check_eq(l["tigers"].size(), int(s.get("tigers", 0)), "%s tigers" % s["id"])
		check_eq(l["mosquitoes"].size(), int(s.get("mosquitoes", 0)), "%s mosquitoes" % s["id"])
		for t in l["things"]:
			check(t["x"] > StageGenerator.START_CLEAR and t["x"] < l["length"] - StageGenerator.END_CLEAR * 0.5, "%s %s at %d is inside the stage" % [s["id"], t["type"], t["x"]])
			check(_things().has(t["type"]), "%s knows %s" % [s["id"], t["type"]])
		for g in l["gas"]:
			check(g["x"] > 0 and g["x"] < l["length"], "%s gas at %d is inside the stage" % [s["id"], g["x"]])


func test_floor_has_no_holes_and_things_stay_dry() -> void:
	for s in _stages():
		var l := StageGenerator.generate(s, _things())
		var x := -1000.0
		while x < l["length"] + 600:
			var covered := false
			for g in l["ground"]:
				covered = covered or (x >= g["x0"] and x < g["x1"])
			check(covered, "%s has floor at %d" % [s["id"], x])
			x += 50
		for t in l["things"]:
			if int(t["tier"]) == 0:
				check(not StageGenerator.floor_at(l, t["x"])["water"], "%s %s at %d isn't in water" % [s["id"], t["type"], t["x"]])


func test_platform_things_stand_on_platforms() -> void:
	for s in _stages():
		var l := StageGenerator.generate(s, _things())
		for t in l["things"]:
			if int(t["tier"]) > 0:
				check(StageGenerator._platform_over(l, t["x"], int(t["tier"])), "%s %s at %d has a platform under it" % [s["id"], t["type"], t["x"]])


## Anything a rank-1 headbutt can't break must be low and narrow enough for a double jump,
## with the stage's gravity, at the starting speed.
func test_everything_can_be_passed_at_rank_1() -> void:
	var base_speed := float(GameData.worlds["speed"]["base_px_s"])
	for s in _stages():
		var g: float = Run.GRAVITY * float(s.get("gravity", 1.0))
		var v0 := sqrt(2.0 * Run.GRAVITY * Run.JUMP_HEIGHT)
		var single_h := v0 * v0 / (2.0 * g)
		var single_t := 2.0 * v0 / g
		for type in s["things"]:
			var d: Dictionary = _things()[type]
			if d.has("air"):
				check(float(d["air"]) > Run.BODY_H + 20, "%s: room to run under a %s" % [s["id"], type])
				continue
			if Progression.headbutt_breaks({"headbutt": 1}, int(d.get("hp", 0))):
				continue
			check(float(d["h"]) < single_h * 1.85, "%s: a double jump clears a %s (h %d, reach %d)" % [s["id"], type, d["h"], single_h * 1.85])
			check(float(d["w"]) + Run.HALF_W * 2 < base_speed * single_t * 1.6, "%s: a double jump is long enough for a %s" % [s["id"], type])
