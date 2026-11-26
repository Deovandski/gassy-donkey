extends Node2D
## The 2016 Unity scene (legacy/2016-unity/Assets/MainGame.unity), rebuilt in Godot.
##
## Every number below was read from MainGame.unity (positions, scales, sizes, colours, texts, script settings);
## the names match the Unity objects. Unity units are turned into pixels by Unity.pos() and friends.
## What the 2016 version did is kept, including what it didn't do yet: only "Select World" and Escape
## do anything; Character, Achievements, Credits and Play have no action, as in 2016.
## The only additions (marked "Port extra") are a way back to the finished game and a caption.

const ART := "res://art/legacy/menu/"
const FONT := preload("res://fonts/LiberationSans-Regular.ttf")
const RotateStar := preload("res://original_2016/rotate_star.gd")
const FakePlanetMotion := preload("res://original_2016/fake_planet_motion.gd")
const MainVesselMovement := preload("res://original_2016/main_vessel_movement.gd")
const SelectWorldHandler := preload("res://original_2016/select_world_handler.gd")
const WorldSelectionSwitcher := preload("res://original_2016/world_selection_switcher.gd")

## Unity UI defaults in 2016: button text colour and the button tints.
const TEXT_GREY := Color(0.19607843, 0.19607843, 0.19607843)
const HIGHLIGHT := Color(0.9607843, 0.9607843, 0.9607843)
const PRESSED := Color(0.7843137, 0.7843137, 0.7843137)

## The planets under "Planets": name, sprite, Unity x, scale, FakePlanetMotion.motionSpeed.
## (Unity called Uranus "Uranos" in the hierarchy; the label said "Uranus".)
const PLANETS := [
	["Mercury", "mercury", 0.0, 7.0, 1.0],
	["Venus", "venus", 100.0, 7.0, 1.0],
	["Earth", "earth", 200.0, 5.0, 1.0],
	["Mars", "mars", 300.0, 4.5, 1.0],
	["Jupiter", "jupiter", 400.0, 6.0, 0.3],
	["Saturn", "saturn", 500.0, 6.0, 0.2],
	["Uranos", "uranus", 600.0, 3.5, 1.0],
	["Neptune", "neptune", 700.0, 3.0, 1.0],
]

var camera: Camera2D
var world_switcher: Node2D


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0))  # Main Camera: solid black

	# "Stars" (Unity scale 15) holds the Sun and the Background; their world values are used directly.
	var stars := Node2D.new()
	stars.name = "Stars"
	add_child(stars)
	_sprite(stars, "Background", ART + "space.png", 0, 508.5, 30.0, -2, RotateStar, {"rotation_speed": 0.1, "forward_rotation": false})
	_sprite(stars, "Sun", ART + "sun.png", 0, -105, 6.0, -1, RotateStar, {"rotation_speed": 4.0, "forward_rotation": false})

	# Main Menu (y 0)
	var main_menu := Node2D.new()
	main_menu.name = "Main Menu"
	main_menu.position = Unity.pos(0, 0)
	add_child(main_menu)
	var menu_canvas := _canvas(main_menu, "Main Menu Canvas")
	_text(menu_canvas, "Gassy Donkey", Vector2(0, 40.9), Vector2(1019, 158.1), 0.1, 200, Color(1, 0.651927, 0.0294118))
	var select_world := _button(menu_canvas, "Select World", Vector2(-17, -9), Vector2(160, 50))
	_button(menu_canvas, "Character", Vector2(15, -9), Vector2(160, 50))
	_button(menu_canvas, "Achievements", Vector2(-17, -23), Vector2(160, 50))
	_button(menu_canvas, "Credits", Vector2(15, -23), Vector2(160, 50))
	_vessel(main_menu)

	# Select World (y 500)
	var world := Node2D.new()
	world.name = "Select World"
	world.position = Unity.pos(0, 500)
	add_child(world)
	var world_canvas := _canvas(world, "Select World Canvas")
	var planet_text := _text(world_canvas, "Planet", Vector2(0, 35), Vector2(686.1, 140), 0.1, 200, Color(0.2119377, 0.7476077, 0.8235294))
	_button(world_canvas, "Play", Vector2(0, -40), Vector2(200, 50))
	world_switcher = Node2D.new()
	world_switcher.name = "Planets"
	world_switcher.set_script(WorldSelectionSwitcher)
	world.add_child(world_switcher)
	for p in PLANETS:
		_sprite(world_switcher, p[0], ART + p[1] + ".png", p[2], 0, p[3], 0, FakePlanetMotion, {"motion_speed": p[4]})
	_text(world_canvas, "Level X recommended", Vector2(0, -30), Vector2(686.1, 140), 0.05, 200, Color(1, 0.769574, 0.4779412))
	world_switcher.setup(planet_text)

	# Main Camera (y 4.78) with SelectWorldHandler
	camera = Camera2D.new()
	camera.name = "Main Camera"
	camera.set_script(SelectWorldHandler)
	camera.position = Unity.pos(0, 4.78)
	add_child(camera)
	camera.make_current()
	camera.setup(world, main_menu)
	select_world.pressed.connect(camera.view_world_selection)

	_port_extras()
	# For screenshots and tests: --param=view:world, --param=planet:<n>
	if Router.params.get("view") == "world":
		camera.view_world_selection()
	for i in int(Router.params.get("planet", "0")):
		world_switcher.move_planets(false)


## A sprite at a Unity world position (relative to `parent`), with a Unity scale and sorting order,
## and the ported script that was on it in Unity, with that script's settings.
func _sprite(parent: Node, node_name: String, texture: String, x: float, y: float, unity_scale: float, order: int,
		script: Script = null, settings := {}) -> Sprite2D:
	var s := Sprite2D.new()
	if script:
		s.set_script(script)
		for key in settings:
			s.set(key, settings[key])
	s.name = node_name
	s.texture = load(texture)
	s.position = Unity.pos(x, y)
	s.scale = Unity.sprite_scale(unity_scale)
	s.z_index = order
	parent.add_child(s)
	return s


## A world-space Unity canvas: its children are laid out in canvas units, one canvas unit = one Unity unit.
## Unity drew canvases (sorting order 1) over the sprites (order 0 and below).
func _canvas(parent: Node, node_name: String) -> Node2D:
	var c := Node2D.new()
	c.name = node_name
	c.scale = Vector2.ONE * Unity.K
	c.z_index = 1
	parent.add_child(c)
	return c


## Places a Control like a Unity RectTransform: centred on `anchored` (y up), `size` in canvas units,
## then scaled by the RectTransform's scale around its centre.
func _place(control: Control, anchored: Vector2, size: Vector2, unity_scale: Vector2) -> void:
	control.size = size
	control.pivot_offset = size / 2
	control.position = Vector2(anchored.x, -anchored.y) - size / 2
	control.scale = unity_scale


## A Unity Text with Best Fit on: the biggest font size (up to max_size) that fits the rectangle.
func _text(canvas: Node2D, text: String, anchored: Vector2, size: Vector2, unity_scale: float, max_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = text + " Text"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", best_fit(text, size, max_size))
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	_place(label, anchored, size, Vector2.ONE * unity_scale)
	return label


static func best_fit(text: String, size: Vector2, max_size: int) -> int:
	for font_size in range(max_size, 0, -1):
		var measured := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if measured.x <= size.x and FONT.get_height(font_size) <= size.y:
			return font_size
	return 1


## A Unity UI Button: white rounded sprite, grey 14 px text, tinted when hovered and pressed.
## Every 2016 button had the same RectTransform scale, 0.18 x 0.2.
func _button(canvas: Node2D, text: String, anchored: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.name = text + " Button"
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 14)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, TEXT_GREY)
	b.add_theme_stylebox_override("normal", _button_box(Color.WHITE))
	b.add_theme_stylebox_override("hover", _button_box(HIGHLIGHT))
	b.add_theme_stylebox_override("pressed", _button_box(PRESSED))
	b.add_theme_stylebox_override("hover_pressed", _button_box(PRESSED))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	canvas.add_child(b)
	_place(b, anchored, size, Vector2(0.18, 0.2))
	return b


static func _button_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	box.border_color = Color(0.75, 0.75, 0.75)
	box.set_border_width_all(1)
	box.anti_aliasing = true
	return box


## "Main Menu Vessel": Unity position (200, 15), scale 6, turned 90 degrees, four frames at 12 frames a second
## (Main Menu Vessel.anim), moved by MainVesselMovement (left, speed 25, max travel distance 500).
func _vessel(parent: Node2D) -> void:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 12.0)
	frames.set_animation_loop("default", true)
	for i in range(1, 5):
		frames.add_frame("default", load(ART + "vessel_%d.png" % i))
	var vessel := AnimatedSprite2D.new()
	vessel.name = "Main Menu Vessel"
	vessel.sprite_frames = frames
	vessel.position = Unity.pos(200, 15)
	vessel.rotation = Unity.rot(90)
	vessel.scale = Unity.sprite_scale(6.0)
	vessel.set_script(MainVesselMovement)
	vessel.travel_direction = "left"
	vessel.vessel_speed = 25.0
	vessel.max_travel_distance = 500.0
	parent.add_child(vessel)
	vessel.play("default")


## Port extra (not in 2016): a way back to the finished game, and a caption saying what this is.
func _port_extras() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Port extras"
	add_child(layer)
	var back := Button.new()
	back.name = "Back"
	back.text = "‹ Gassy Donkey (finished game)"
	back.position = Vector2(12, 12)
	back.add_theme_font_override("font", FONT)
	back.add_theme_font_size_override("font_size", 18)
	back.modulate = Color(1, 1, 1, 0.75)
	back.pressed.connect(func() -> void: Router.go("main_menu"))
	layer.add_child(back)
	var caption := Label.new()
	caption.name = "Caption"
	caption.text = "The 2016 Unity version, ported to Godot. Only Select World worked back then; swipe the planets, Esc goes back."
	caption.add_theme_font_override("font", FONT)
	caption.add_theme_font_size_override("font_size", 15)
	caption.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 10)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(caption)
