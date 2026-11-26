class_name Donkey
extends Node2D
## The donkey on screen: the 2016 run frames (1 to 4), frame 3 in the air and frame 5 (head down)
## for a headbutt. Its position is its feet.

const SCALE := 0.5
## The feet sit 295 px down the 300 px frames.
const FEET := 295.0

var sprite: AnimatedSprite2D


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("run")
	frames.add_animation("air")
	frames.add_animation("headbutt")
	frames.remove_animation("default")
	var dir := "res://art/legacy/donkey/"
	for i in range(1, 5):
		frames.add_frame("run", load(dir + "run_%d.png" % i))
	frames.add_frame("air", load(dir + "run_3.png"))
	frames.add_frame("headbutt", load(dir + "run_5.png"))
	frames.set_animation_speed("run", 10.0)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * SCALE
	sprite.position = Vector2(0, -(FEET - 150.0) * SCALE)
	add_child(sprite)
	sprite.play("run")


func show_state(on_ground: bool, headbutting: bool, run_speed_factor: float) -> void:
	var anim := "headbutt" if headbutting else ("run" if on_ground else "air")
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.speed_scale = run_speed_factor
	sprite.position.x = 18.0 if headbutting else 0.0


func blink(on: bool, t: float) -> void:
	sprite.modulate.a = (0.35 if fmod(t, 0.16) < 0.08 else 1.0) if on else 1.0
