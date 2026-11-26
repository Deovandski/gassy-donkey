extends Screen
## World selection, grown from the 2016 one: swipe (or use the arrows) between planets, the name in the
## 2016 cyan above, "Level X recommended" in the 2016 peach below, then pick a stage.
## Phase I worlds are on Earth; the other planets say "Coming soon!" (2016 sketch).

const ART := "res://art/legacy/menu/"
const FakePlanetMotion := preload("res://original_2016/fake_planet_motion.gd")

var entries: Array = []  # {"kind": "world"/"soon", "data": {...}}
var index := 0
var _name: Label
var _planet: Sprite2D
var _note: Label
var _stages: HBoxContainer
var _press := Vector2.ZERO
var _donkey: Sprite2D
var _t := 0.0


func _ready() -> void:
	add_backdrop(false, true)
	Audio.menu_music()
	for w in GameData.world_list():
		entries.append({"kind": "world", "data": w})
	for p in GameData.worlds.get("coming_soon", []):
		entries.append({"kind": "soon", "data": p})
	index = clampi(int(Router.params.get("world_index", _first_open_index())), 0, entries.size() - 1)

	add_back_button()
	_name = UiTheme.label("", 72, UiTheme.CYAN, true)
	_name.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.position.y = 14
	_name.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_name)

	_planet = Sprite2D.new()
	_planet.set_script(FakePlanetMotion)
	_planet.motion_speed = 1.5
	add_child(_planet)

	_donkey = Sprite2D.new()
	_donkey.texture = load("res://art/legacy/donkey_space/run_3.png")
	_donkey.scale = Vector2(0.55, 0.55)
	add_child(_donkey)

	for dir in [-1, 1]:
		var arrow := UiTheme.button("‹" if dir < 0 else "›", func() -> void: step(dir), 70)
		arrow.add_theme_font_size_override("font_size", 44)
		arrow.set_anchors_preset(Control.PRESET_CENTER_LEFT if dir < 0 else Control.PRESET_CENTER_RIGHT)
		arrow.position = Vector2(30, -80) if dir < 0 else Vector2(-100, -80)
		arrow.name = "Left" if dir < 0 else "Right"
		add_child(arrow)

	_note = UiTheme.label("", 30, UiTheme.PEACH, true)
	_note.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_note.position.y = -238
	add_child(_note)

	_stages = HBoxContainer.new()
	_stages.alignment = BoxContainer.ALIGNMENT_CENTER
	_stages.add_theme_constant_override("separation", 20)
	_stages.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_stages.offset_top = -190
	_stages.offset_bottom = -24
	add_child(_stages)

	get_viewport().size_changed.connect(_layout)
	show_entry()


func _first_open_index() -> int:
	for i in range(entries.size() - 1, -1, -1):
		if entries[i]["kind"] == "world" and SaveManager.is_world_open(entries[i]["data"]["id"]):
			return i
	return 0


func step(dir: int) -> void:
	var next := clampi(index + dir, 0, entries.size() - 1)
	if next != index:
		index = next
		Audio.play("click", 1.2)
		show_entry()


func _layout() -> void:
	var size := get_viewport_rect().size
	_planet.position = Vector2(size.x / 2, size.y * 0.37)
	_donkey.position = Vector2(size.x * 0.82, size.y * 0.33)


func show_entry() -> void:
	var e: Dictionary = entries[index]
	var d: Dictionary = e["data"]
	_name.text = d["name"]
	_planet.texture = load(ART + d["planet"] + ".png")
	var tex_size := _planet.texture.get_size()
	_planet.scale = Vector2.ONE * (230.0 / maxf(tex_size.x, tex_size.y)) * (1.6 if d["planet"] == "saturn" else 1.0)
	_layout()
	for c in _stages.get_children():
		c.queue_free()
	if e["kind"] == "soon":
		_note.text = "Coming soon!"
		_planet.modulate = Color(0.6, 0.6, 0.7)
		return
	_planet.modulate = Color.WHITE
	var level := SaveManager.level()
	var recommended := 0
	for s in d["stages"]:
		var open := SaveManager.is_stage_open(s["id"])
		_stages.add_child(_stage_card(d, s, open))
		if open and not SaveManager.is_stage_done(s["id"]) and recommended == 0:
			recommended = int(s["recommended_level"])
	if not SaveManager.is_world_open(d["id"]):
		_note.text = "Finish World %d to open this world" % (int(d["number"]) - 1)
	elif recommended > level:
		_note.text = "Level %d recommended" % recommended
	else:
		_note.text = "World %d" % int(d["number"])


func _stage_card(world: Dictionary, s: Dictionary, open: bool) -> Button:
	var rec: Dictionary = SaveManager.stage_record(s["id"])
	var lines := ["%d. %s" % [int(s["id"].right(1)), s["name"]]]
	if open:
		lines.append("Level %d recommended" % int(s["recommended_level"]))
		if rec.is_empty():
			lines.append("%d m · new" % int(s["length_m"]))
		else:
			var tick := "  ✓" if rec.get("done", false) else ""
			lines.append("best %d / %d m%s" % [int(rec["best_m"]), int(s["length_m"]), tick])
			lines.append("%s %d / %d%s" % [world["gas_item_name"], int(rec["best_gas"]), int(s["gas_items"]), "  ★" if rec.get("all_gas", false) else ""])
	else:
		lines.append("Locked")
		lines.append("Finish the stage before")
	var b := Button.new()
	b.text = "\n".join(lines)
	b.custom_minimum_size = Vector2(300, 150)
	b.add_theme_font_size_override("font_size", 21)
	b.disabled = not open
	b.pressed.connect(func() -> void:
		Audio.play("click")
		Router.go("run", {"stage": s["id"], "world_index": index}))
	return b


func _process(delta: float) -> void:
	_t += delta
	if _donkey:
		_donkey.position.y = get_viewport_rect().size.y * 0.33 + sin(_t * 1.3) * 14
		_donkey.rotation = sin(_t * 0.7) * 0.12


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_press = event.position
		else:
			var d: Vector2 = event.position - _press
			if absf(d.x) > 60 and absf(d.x) > absf(d.y) * 1.5:
				step(-1 if d.x > 0 else 1)
	elif event.is_action_pressed("ui_left"):
		step(-1)
	elif event.is_action_pressed("ui_right"):
		step(1)
