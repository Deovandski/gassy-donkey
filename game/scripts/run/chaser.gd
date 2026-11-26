class_name Chaser
extends Node2D
## Something chasing the donkey from behind.
## - mosquito (2014 sketch): flies after the donkey; it gains whenever the donkey slows down (water, bumps,
##   headbutts) and bites when it catches up. A fart scares it off.
## - tiger (2016 notes): waits on the floor facing the donkey. Jump over it and it turns and chases you;
##   only a fart with farting power 2 or more scares it away. It can't climb onto platforms.

signal bite(chaser: Chaser)

enum State { WAITING, CHASING, LEAVING }

var kind := "mosquito"
var state := State.CHASING
## Distance behind the donkey's x, in pixels (positive = behind).
var behind := 260.0
var _sprite: AnimatedSprite2D
var _t := 0.0
var _life := 0.0
var _bites := 0
var _leave_dir := Vector2(-1, -1)


func setup(chaser_kind: String) -> void:
	kind = chaser_kind
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 14.0 if kind == "mosquito" else 7.0)
	frames.add_frame("default", load("res://art/new/%s_1.png" % kind))
	frames.add_frame("default", load("res://art/new/%s_2.png" % kind))
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.flip_h = kind == "mosquito"  # drawn facing left; it chases rightwards
	if kind == "tiger":
		_sprite.position.y = -56
		_sprite.flip_h = true  # waiting: faces the donkey
		state = State.WAITING
	add_child(_sprite)
	_sprite.play()


## Moves it for one frame. world_speed: how fast the donkey would run with no slow-downs or boosts;
## donkey: {"x", "y", "speed", "on_floor"}.
func step(delta: float, world_speed: float, donkey: Dictionary) -> void:
	_t += delta
	match state:
		State.WAITING:
			if donkey["x"] > position.x + 70:
				state = State.CHASING
				behind = donkey["x"] - position.x
				_sprite.flip_h = false
				Audio.play("growl")
		State.CHASING:
			_life += delta
			var own := world_speed + (40.0 if kind == "mosquito" else 60.0)
			behind -= (own - float(donkey["speed"])) * delta
			behind = maxf(behind, 30.0)
			position.x = donkey["x"] - behind
			if kind == "mosquito":
				position.y = lerpf(position.y, donkey["y"] - 70 + sin(_t * 6) * 18, 4 * delta)
			else:
				position.y = StageGenerator.FLOOR_Y
			var close: bool = behind < 80.0 and (kind == "mosquito" or donkey["on_floor"])
			if close:
				bite.emit(self)
				_bites += 1
				behind = 300.0
			var limit := 26.0 if kind == "mosquito" else 14.0
			var max_bites := 2 if kind == "mosquito" else 1
			if _life > limit or _bites >= max_bites:
				leave(Vector2(-1, -0.6))
		State.LEAVING:
			position += _leave_dir * 700 * delta
			modulate.a = maxf(0, modulate.a - delta * 0.7)
			if modulate.a <= 0:
				queue_free()


func leave(dir: Vector2) -> void:
	state = State.LEAVING
	_leave_dir = dir.normalized()
	_sprite.flip_h = dir.x < 0 if kind == "tiger" else dir.x > 0


## Its hit box in world coordinates, for a tiger still waiting on the floor.
func rect() -> Rect2:
	return Rect2(position.x - 90, position.y - 90, 180, 90)
