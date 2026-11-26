extends Node2D
## Port of Assets/Scripts/WorldSelectionSwitcher.cs (2016): swipe left or right to move between the planets,
## with a 0.3 second pause after each swipe, and show the selected planet's name.
##
## Kept as it was in 2016:
## - swipes are read anywhere on the screen, even while the main menu is showing;
## - a swipe needs only 5 pixels; shorter is a tap;
## - the planets jump by one place, with no slide. Unity moved the "Planets" object by 50 units and then
##   every planet by another 50 (GetComponentsInChildren includes the parent), so each planet moved 100
##   units, the gap between planets. Here the planets move by that same 100 units.

const PLANET_SPACING := 100.0  ## Unity units between planets

var min_swipe_length := 5.0
var first_press_pos := Vector2.ZERO
var current_swipe := Vector2.ZERO
var swipe_left := false
var swipe_right := false
var after_swipe_wait_time := 0.3
var current_time := 0.0
var disable_swipe_detection := false

var planets: Array[Node2D] = []
var planets_count := 0
var current_planet_index := 0
var planet_text_name: Label


func setup(text_label: Label) -> void:
	planet_text_name = text_label
	for child in get_children():
		if child is Node2D:
			planets.append(child)
	planets_count = planets.size()
	if planets_count < 0 or planet_text_name == null:
		push_error("WoldSelectionSwitcher Initialization Issue.")
	else:
		update_planet_text_name()


func _process(delta: float) -> void:
	if disable_swipe_detection:
		current_time -= delta
		if current_time <= 0:
			current_time = 0.0
			disable_swipe_detection = false
	else:
		if swipe_left:
			move_planets(false)
			swipe_left = false
			current_time = after_swipe_wait_time
			disable_swipe_detection = true
		elif swipe_right:
			move_planets(true)
			swipe_right = false
			current_time = after_swipe_wait_time
			disable_swipe_detection = true


func move_planets(is_swipe_right: bool) -> void:
	if is_swipe_right and current_planet_index == 0:
		pass  # Do nothing
	elif is_swipe_right and current_planet_index > 0:
		for child in planets:
			child.position.x += PLANET_SPACING * Unity.K
		current_planet_index -= 1
	elif planets_count - 1 > current_planet_index:
		for child in planets:
			child.position.x -= PLANET_SPACING * Unity.K
		current_planet_index += 1
	update_planet_text_name()


func update_planet_text_name() -> void:
	planet_text_name.text = planet_name(current_planet_index)


static func planet_name(index: int) -> String:
	match index:
		0: return "Mercury"
		1: return "Venus"
		2: return "Earth"
		3: return "Mars"
		4: return "Jupiter"
		5: return "Saturn"
		6: return "Uranus"
		7: return "Neptune"
		_: return "---"


func _input(event: InputEvent) -> void:
	# Unity read the first touch (or the mouse) every frame; the mouse arrives here as a touch too.
	if not (event is InputEventScreenTouch) or event.index != 0 or disable_swipe_detection:
		return
	if event.pressed:
		first_press_pos = event.position
		return
	current_swipe = event.position - first_press_pos
	if current_swipe.length() < min_swipe_length:
		return  # this was a tap, not a swipe
	current_swipe = current_swipe.normalized()
	read_swipe()


## Unity's y axis points up and Godot's down; only left and right swipes do anything, so it doesn't matter.
func read_swipe() -> void:
	if absf(current_swipe.x) < 0.5 and current_swipe.y != 0:
		pass  # Do not act upon swipe up or down
	elif current_swipe.x < 0 and current_swipe.y > -0.5 and current_swipe.y < 0.5:
		swipe_left = true
		current_swipe = Vector2.ZERO
	elif current_swipe.x > 0 and current_swipe.y > -0.5 and current_swipe.y < 0.5:
		swipe_right = true
		current_swipe = Vector2.ZERO
