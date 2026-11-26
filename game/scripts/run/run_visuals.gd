class_name RunVisuals
## Draws a stage: the sky and its scrolling layers, the floor, water and platforms, and the finish flag.
## World 1 (Amazon) uses the 2016 World 1 platform art (grass top, dirt blocks, water top); World 2 (desert)
## uses sand versions of it at the same sizes (art/new/).

const W1 := "res://art/legacy/world1/"
const NEW := "res://art/new/"
const FLOOR_Y := StageGenerator.FLOOR_Y
const SCREEN_H := 720.0
const BLOCK_SCALE := 0.5  # the 2016 dirt blocks are 222 x 422; half size reads as bricks
const PLATFORM_DEPTH := 70.0

var parallax: Array = []  # [{sprite, factor}]


## The sky and three scrolling layers, under a CanvasLayer so they don't move with the world.
func build_background(parent: Node, world: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = -5
	parent.add_child(layer)
	var sky := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color(world["sky_top"]))
	grad.gradient.set_color(1, Color(world["sky_bottom"]))
	grad.fill_from = Vector2(0, 0)
	grad.fill_to = Vector2(0, 1)
	sky.texture = grad
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.add_child(sky)
	var prefix: String = "amazon" if world["id"] == "amazon" else "desert"
	_layer(layer, NEW + "clouds.png", 10, 0.05)
	_layer(layer, NEW + prefix + "_far.png", FLOOR_Y - 560, 0.15)
	_layer(layer, NEW + prefix + "_near.png", FLOOR_Y - 600 + 30, 0.4)


func _layer(parent: Node, texture: String, y: float, factor: float) -> void:
	var s := Sprite2D.new()
	s.texture = load(texture)
	s.centered = false
	s.region_enabled = true
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.position = Vector2(0, y)
	s.region_rect = Rect2(0, 0, 4096, s.texture.get_height())
	parent.add_child(s)
	parallax.append({"sprite": s, "factor": factor})


func scroll_background(scroll_x: float, view_width: float) -> void:
	for p in parallax:
		var s: Sprite2D = p["sprite"]
		s.region_rect = Rect2(scroll_x * p["factor"], 0, view_width + 8, s.texture.get_height())


## Floor, water, platforms and the finish flag, as children of the moving world node.
func build_world(world_node: Node2D, layout: Dictionary, world: Dictionary) -> void:
	var sand: bool = world["ground"] == "sand"
	var top_tex: Texture2D = load(NEW + "sand_top.png") if sand else load(W1 + "grass_top.png")
	var block_a: Texture2D = load(NEW + "sandstone_a.png") if sand else load(W1 + "dirt_light_a.png")
	var block_b: Texture2D = load(NEW + "sandstone_b.png") if sand else load(W1 + "dirt_dark_a.png")
	for g in layout["ground"]:
		var x0: float = g["x0"]
		var w: float = g["x1"] - g["x0"]
		if g["water"]:
			var deep := ColorRect.new()
			deep.color = Color(0.12, 0.36, 0.45)
			deep.position = Vector2(x0, FLOOR_Y + 14)
			deep.size = Vector2(w, SCREEN_H - FLOOR_Y + 300)
			world_node.add_child(deep)
			world_node.add_child(_tiled(load(W1 + "water_top.png"), Vector2(x0, FLOOR_Y - 4), Vector2(w, 37), 1.0))
		else:
			world_node.add_child(_tiled(block_b, Vector2(x0, FLOOR_Y + 18), Vector2(w, SCREEN_H - FLOOR_Y + 300), BLOCK_SCALE))
			world_node.add_child(_tiled(top_tex, Vector2(x0, FLOOR_Y - 8), Vector2(w, 37), 1.0))
	for p in layout["platforms"]:
		var y: float = StageGenerator.TIER_Y[int(p["tier"])]
		var w: float = p["x1"] - p["x0"]
		world_node.add_child(_tiled(block_a, Vector2(p["x0"], y + 14), Vector2(w, PLATFORM_DEPTH), BLOCK_SCALE))
		world_node.add_child(_tiled(top_tex, Vector2(p["x0"] - 6, y - 8), Vector2(w + 12, 37), 1.0))
	var flag := Sprite2D.new()
	flag.texture = load(NEW + "finish_flag.png")
	flag.centered = false
	flag.position = Vector2(layout["length"], FLOOR_Y - 165)
	world_node.add_child(flag)


## A texture repeated over a rectangle (scaled by `tex_scale`).
static func _tiled(tex: Texture2D, pos: Vector2, size: Vector2, tex_scale: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	r.position = pos
	r.scale = Vector2.ONE * tex_scale
	r.size = size / tex_scale
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
