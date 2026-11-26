extends TestSuite
## The 2016 port behaves like the Unity scripts did (legacy/2016-unity/Assets/Scripts/).

const Switcher := preload("res://original_2016/world_selection_switcher.gd")
const Vessel := preload("res://original_2016/main_vessel_movement.gd")
const Wobble := preload("res://original_2016/fake_planet_motion.gd")


func test_planet_names_match_unity() -> void:
	var names := ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
	for i in names.size():
		check_eq(Switcher.planet_name(i), names[i], "planet %d" % i)
	check_eq(Switcher.planet_name(8), "---", "past Neptune")


func test_swipes_stop_at_both_ends_and_wait() -> void:
	var s: Node2D = Switcher.new()
	for i in 8:
		var p := Node2D.new()
		p.position.x = i * 100 * Unity.K
		s.add_child(p)
	var label := Label.new()
	s.setup(label)
	check_eq(label.text, "Mercury", "starts on Mercury")
	s.move_planets(true)
	check_eq(s.current_planet_index, 0, "can't go before Mercury")
	for i in 10:
		s.move_planets(false)
	check_eq(s.current_planet_index, 7, "stops at Neptune")
	check_eq(label.text, "Neptune", "label follows")
	check(is_equal_approx(s.planets[7].position.x, 0.0), "the selected planet is in the middle")
	# a swipe starts the 0.3 s wait
	s.swipe_left = true
	s._process(0.0)
	check(s.disable_swipe_detection, "waits after a swipe")
	s._process(0.31)
	check(not s.disable_swipe_detection, "ready again after 0.3 s")
	s.free()
	label.free()


func test_vessel_loops_after_its_travel_distance() -> void:
	var v: Node2D = Vessel.new()
	v.rotation = Unity.rot(90)
	v.position = Unity.pos(200, 15)
	v.vessel_speed = 25.0
	v.max_travel_distance = 500.0
	var start := v.position
	for i in 20 * 60:  # 20 s at 60 fps: 500 units at 25 units/s
		v._process(1.0 / 60.0)
	check(v.position.x < start.x, "flies left")
	for i in 2:
		v._process(1.0 / 60.0)
	check(absf(v.position.x - start.x) < 25 * Unity.K / 30.0, "back at the start after 500 units (x %d, start %d)" % [v.position.x, start.x])
	v.free()


func test_planet_rocks_back_after_10_seconds() -> void:
	var p: Node2D = Wobble.new()
	p.motion_speed = 1.0
	for i in 600:
		p._process(1.0 / 60.0)
	var after_10 := p.rotation
	check(absf(rad_to_deg(after_10) + 10.0) < 0.2, "turned 10 degrees counter-clockwise (%f)" % rad_to_deg(after_10))
	for i in 601:
		p._process(1.0 / 60.0)
	check(absf(p.rotation) < deg_to_rad(0.2), "turned back (%f)" % rad_to_deg(p.rotation))
	p.free()
