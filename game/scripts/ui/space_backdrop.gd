extends Node2D
## The 2016 main-menu sky, reused behind the finished game's menus: the starfield turning slowly, the Sun
## at the bottom, and the vessel flying past. It uses the ported 2016 scripts (game/original_2016/).
## Put it under a CanvasLayer with layer -1; it keeps itself centred when the window changes size.

const ART := "res://art/legacy/menu/"
const RotateStar := preload("res://original_2016/rotate_star.gd")
const MainVesselMovement := preload("res://original_2016/main_vessel_movement.gd")

@export var show_sun := true
@export var show_vessel := true


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.set_script(RotateStar)
	bg.rotation_speed = 0.6
	bg.forward_rotation = false
	bg.texture = load(ART + "space.png")
	bg.scale = Unity.sprite_scale(14.0)
	bg.modulate = Color(1, 1, 1, 0.9)
	add_child(bg)
	if show_sun:
		var sun := Sprite2D.new()
		sun.set_script(RotateStar)
		sun.rotation_speed = 4.0
		sun.forward_rotation = false
		sun.texture = load(ART + "sun.png")
		sun.position = Unity.pos(0, -105 - 4.78)
		sun.scale = Unity.sprite_scale(6.0)
		add_child(sun)
	if show_vessel:
		var frames := SpriteFrames.new()
		frames.set_animation_speed("default", 12.0)
		for i in range(1, 5):
			frames.add_frame("default", load(ART + "vessel_%d.png" % i))
		var vessel := AnimatedSprite2D.new()
		vessel.set_script(MainVesselMovement)
		vessel.travel_direction = "left"
		vessel.vessel_speed = 25.0
		vessel.max_travel_distance = 500.0
		vessel.sprite_frames = frames
		vessel.position = Unity.pos(130, 22)
		vessel.rotation = Unity.rot(90)
		vessel.scale = Unity.sprite_scale(4.0)
		vessel.modulate = Color(1, 1, 1, 0.9)
		add_child(vessel)
		vessel.play()
	get_viewport().size_changed.connect(_center)
	_center()


func _center() -> void:
	position = get_viewport_rect().size / 2
