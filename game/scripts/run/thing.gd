class_name Thing
extends Node2D
## One obstacle or enemy on a stage (types and sizes in data/worlds.json "things").
## Its position is its feet: the middle of its bottom edge, on the floor or a platform.

signal shot(from: Vector2)

const NEW := "res://art/new/"

var type := ""
var data: Dictionary = {}
var tier := 0
var alive := true
var hp := 0
var _sprite: AnimatedSprite2D
var _t := 0.0
var _shoot_timer := 0.0
var _fly := Vector2.ZERO
var _spin := 0.0


func setup(thing_type: String, thing_data: Dictionary, x: float, thing_tier: int) -> void:
	type = thing_type
	data = thing_data
	tier = thing_tier
	hp = int(data.get("hp", 0))
	var y: float = StageGenerator.TIER_Y[tier] - float(data.get("air", 0))
	position = Vector2(x, y)
	_shoot_timer = float(data.get("shoots", 0)) * 0.5
	_sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 5.0)
	var art: String = data.get("art", type)
	if ResourceLoader.exists(NEW + art + "_1.png"):
		frames.add_frame("default", load(NEW + art + "_1.png"))
		frames.add_frame("default", load(NEW + art + "_2.png"))
	else:
		frames.add_frame("default", load(NEW + art + ".png"))
	_sprite.sprite_frames = frames
	var tex: Texture2D = frames.get_frame_texture("default", 0)
	_sprite.position = Vector2(0, -tex.get_height() / 2.0 + 4)
	# The art faces right; things on the way face the donkey (left), except the cowboy, drawn aiming left.
	_sprite.flip_h = type in ["snake", "rattlesnake", "tiger"]
	add_child(_sprite)
	if type == "cowboy":
		_sprite.stop()
	else:
		_sprite.play()
	if data.has("air"):
		var string := Line2D.new()
		string.points = PackedVector2Array([Vector2(0, -tex.get_height() + 4), Vector2(0, -900)])
		string.width = 3
		string.default_color = Color(0.35, 0.23, 0.1)
		add_child(string)
		move_child(string, 0)


## The hit box in world coordinates (a little smaller than the art, to be fair).
func rect() -> Rect2:
	var w := float(data.get("w", 60))
	var h := float(data.get("h", 60))
	return Rect2(position.x - w / 2, position.y - h, w, h)


func _process(delta: float) -> void:
	_t += delta
	if not alive:
		position += _fly * delta
		_fly.y += 1600 * delta
		rotation += _spin * delta
		modulate.a = maxf(0, modulate.a - delta * 0.8)
		if position.y > 1400:
			queue_free()
		return
	match type:
		"hive":
			rotation = sin(_t * 2.0) * 0.08
		"bear":
			_sprite.scale = Vector2(1, 1 + sin(_t * 3) * 0.02)
		"cactus_small", "cactus_tall", "rock_small", "rock_big":
			pass


## Called every frame by the run with the donkey's world x: snakes slither, cowboys shoot.
func act(delta: float, donkey_x: float) -> void:
	if not alive:
		return
	var ahead := position.x - donkey_x
	if data.has("moves") and ahead < 1100 and ahead > -200:
		position.x += float(data["moves"]) * delta
	if data.has("shoots") and ahead < 1000 and ahead > 150:
		_shoot_timer -= delta
		if _shoot_timer <= 0:
			_shoot_timer = float(data["shoots"])
			_sprite.frame = 1
			get_tree().create_timer(0.15).timeout.connect(func() -> void:
				if is_instance_valid(_sprite):
					_sprite.frame = 0)
			shot.emit(position + Vector2(-52, -86))


## Knocked out by a headbutt: flies off spinning.
func knock_out() -> void:
	alive = false
	_fly = Vector2(520, -700)
	_spin = 9.0
