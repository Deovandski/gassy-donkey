extends CanvasLayer
## The run's screen furniture, laid out like the 2016 control-overlay sketch: hearts and gas top left,
## distance and speed in the middle, XP and level top right; fart and headbutt buttons on the left, and the
## right side of the screen is the jump area (tap to jump, tap again to double jump, swipe down to drop).
## Also the pause menu and the results.

const NEW := "res://art/new/"

var run  # the run (scripts/run/run.gd)
var _hearts: HBoxContainer
var _gas: ProgressBar
var _distance: ProgressBar
var _distance_label: Label
var _speed: Label
var _level: Label
var _xp: ProgressBar
var _toast: Label
var _pause_panel: Control
var _results: Control
var _touch_root: Control
var _hint: Label
var _touch_start := {}
var _shake := 0.0
var _heart_full: Texture2D = load(NEW + "heart_full.png")
var _heart_empty: Texture2D = load(NEW + "heart_empty.png")
var _shown_hearts := -1


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.theme()
	add_child(root)

	# Top left: hearts, gas
	var tl := VBoxContainer.new()
	tl.position = Vector2(18, 12)
	tl.add_theme_constant_override("separation", 4)
	root.add_child(tl)
	_hearts = HBoxContainer.new()
	_hearts.add_theme_constant_override("separation", 2)
	tl.add_child(_hearts)
	var gas_row := HBoxContainer.new()
	var gas_icon := TextureRect.new()
	gas_icon.texture = load(NEW + "gas_icon.png")
	gas_row.add_child(gas_icon)
	_gas = _bar(Color(0.62, 0.83, 0.42), Vector2(200, 24))
	_gas.max_value = run.GAS_MAX
	gas_row.add_child(_gas)
	var gas_label := UiTheme.label("Gas", 18, Color.WHITE, true)
	gas_row.add_child(gas_label)
	tl.add_child(gas_row)

	# Top middle: distance and speed
	var tm := VBoxContainer.new()
	tm.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tm.position = Vector2(-170, 10)
	tm.custom_minimum_size = Vector2(340, 0)
	root.add_child(tm)
	_distance_label = UiTheme.label("", 22, Color.WHITE, true)
	_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tm.add_child(_distance_label)
	_distance = _bar(UiTheme.ORANGE, Vector2(340, 16))
	_distance.max_value = run.layout["length"]
	tm.add_child(_distance)
	_speed = UiTheme.label("", 18, UiTheme.PEACH, true)
	_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tm.add_child(_speed)

	# Top right: level, XP, pause
	var tr := HBoxContainer.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tr.position = Vector2(-330, 12)
	tr.add_theme_constant_override("separation", 10)
	root.add_child(tr)
	var lv := VBoxContainer.new()
	_level = UiTheme.label("", 22, UiTheme.CYAN, true)
	lv.add_child(_level)
	_xp = _bar(UiTheme.CYAN, Vector2(200, 14))
	lv.add_child(_xp)
	tr.add_child(lv)
	tr.add_child(UiTheme.icon_button(load(NEW + "icon_pause.png"), pause, 64))

	_toast = UiTheme.label("", 40, UiTheme.ORANGE, true)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position.y = 130
	_toast.modulate.a = 0
	root.add_child(_toast)

	_touch_root = Control.new()
	_touch_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_touch_root)
	_build_touch()
	_build_pause(root)
	refresh()


func _bar(color: Color, size: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = size
	b.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(int(size.y / 2))
	fill.set_border_width_all(2)
	fill.border_color = UiTheme.INK
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	bg.set_corner_radius_all(int(size.y / 2))
	bg.set_border_width_all(2)
	bg.border_color = UiTheme.INK
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", bg)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


# ------------------------------------------------------------------------------------------- touch

func _build_touch() -> void:
	var show_buttons := bool(SaveManager.setting("touch_buttons"))
	var size := get_viewport().get_visible_rect().size
	for spec in [["fart", "icon_fart", Vector2(28, size.y - 300)], ["headbutt", "icon_headbutt", Vector2(28, size.y - 160)]]:
		var b := TouchScreenButton.new()
		b.texture_normal = _circle_icon(load(NEW + spec[1] + ".png"), false)
		b.texture_pressed = _circle_icon(load(NEW + spec[1] + ".png"), true)
		b.action = spec[0]
		b.position = spec[2]
		b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS if show_buttons else TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		b.passby_press = false
		b.name = "Touch_" + spec[0]
		add_child(b)
	_hint = UiTheme.label("Tap the right side to jump (twice to go up a level) · swipe down to drop", 22, Color.WHITE, true)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.position.y = -50
	_hint.visible = DisplayServer.is_touchscreen_available() or show_buttons
	_touch_root.add_child(_hint)
	var tw := _hint.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(_hint, "modulate:a", 0.0, 1.0)


## A round backing for a touch button icon (128 x 128).
static func _circle_icon(icon: Texture2D, pressed: bool) -> ImageTexture:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var c := Color(UiTheme.ORANGE, 0.9) if pressed else Color(0, 0, 0, 0.42)
	for py in 128:
		for px in 128:
			var d := Vector2(px - 63.5, py - 63.5).length()
			if d <= 62:
				img.set_pixel(px, py, c if d < 57 else Color(1, 1, 1, 0.85))
	var src := icon.get_image()
	src.resize(88, 88, Image.INTERPOLATE_BILINEAR)
	img.blend_rect(src, Rect2i(0, 0, 88, 88), Vector2i(20, 20))
	return ImageTexture.create_from_image(img)


func _input(event: InputEvent) -> void:
	if run.over or get_tree().paused:
		return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	var width := get_viewport().get_visible_rect().size.x
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < width * 0.33:
				return  # the left side belongs to the fart and headbutt buttons
			if event.position.y < 90 and event.position.x > width - 120:
				return  # the pause button
			_touch_start[event.index] = {"pos": event.position, "dropped": false}
			run.do_jump()
		else:
			_touch_start.erase(event.index)
	elif _touch_start.has(event.index):
		var start: Dictionary = _touch_start[event.index]
		var d: Vector2 = event.position - start["pos"]
		if not start["dropped"] and d.y > 60 and d.y > absf(d.x) * 1.2:
			start["dropped"] = true
			run.do_drop()


# ------------------------------------------------------------------------------------------- every frame

func refresh() -> void:
	if run.hearts != _shown_hearts:
		_shown_hearts = run.hearts
		for c in _hearts.get_children():
			c.queue_free()
		for i in run.max_hearts:
			var h := TextureRect.new()
			h.texture = _heart_full if i < run.hearts else _heart_empty
			_hearts.add_child(h)
	_gas.value = run.gas
	_gas.modulate = Color(1.3, 1.3, 0.7) if run.gas >= run.GAS_MAX - 0.5 else Color.WHITE
	_distance.value = minf(run.x, run.layout["length"])
	_distance_label.text = "%d / %d m" % [int(run.metres()), int(run.stage["length_m"])]
	_speed.text = "Speed %d" % Progression.speed_level(run.metres(), run.speed_data)
	var xp: int = int(SaveManager.data["xp"]) + run.xp_run
	var level := Progression.level_for_xp(xp, SaveManager.xp_table())
	var p := Progression.level_progress(xp, SaveManager.xp_table())
	_level.text = "LV %d   XP %d" % [level, xp]
	_xp.max_value = maxi(1, p.y)
	_xp.value = p.x if p.y > 0 else 1


func _process(delta: float) -> void:
	if _shake > 0:
		_shake = maxf(0, _shake - delta)
		run.position = Vector2(randf_range(-8, 8), randf_range(-6, 6)) * (_shake / 0.25)
	elif run.position != Vector2.ZERO:
		run.position = Vector2.ZERO
	if Input.is_action_just_pressed("pause") or (Input.is_action_just_pressed("ui_cancel") and not run.over):
		if get_tree().paused:
			resume()
		elif _results == null:
			pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _results == null:
		pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and not run.over and not get_tree().paused:
		pause()


func shake() -> void:
	_shake = 0.25


## A short message rising from a point in the world.
func float_text(text: String, world_pos: Vector2, color := Color.WHITE, size := 26) -> void:
	var l := UiTheme.label(text, size, color, true)
	l.position = world_pos - Vector2(140, 0)
	l.custom_minimum_size = Vector2(280, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run.world.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 90, 1.3)
	tw.tween_property(l, "modulate:a", 0.0, 1.3).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


func toast(text: String, seconds := 1.5) -> void:
	_toast.text = text
	_toast.modulate.a = 1
	var tw := _toast.create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------------------------------------- pause and results

func _build_pause(root: Control) -> void:
	_pause_panel = _panel_screen(root)
	var v: VBoxContainer = _pause_panel.get_meta("box")
	v.add_child(UiTheme.title("Paused", 56))
	v.add_child(UiTheme.button("Keep running", resume, 340))
	v.add_child(UiTheme.button("Start the stage again", func() -> void: Router.go("run", Router.params), 340))
	v.add_child(UiTheme.button("Back to the worlds", _to_map, 340))
	_pause_panel.visible = false


func _panel_screen(root: Control) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	dim.set_meta("box", v)
	return dim


func pause() -> void:
	if run.over:
		return
	get_tree().paused = true
	_pause_panel.visible = true
	_pause_panel.get_meta("box").get_child(1).grab_focus()


func resume() -> void:
	get_tree().paused = false
	_pause_panel.visible = false


func _to_map() -> void:
	Router.go("world_select", {"world_index": Router.params.get("world_index", 0)})


func show_results(r: Dictionary) -> void:
	_results = _panel_screen(get_child(0))
	var v: VBoxContainer = _results.get_meta("box")
	v.add_child(UiTheme.title("Stage clear!" if r["finished"] else "Out of hearts!", 56))
	var lines := [
		"Distance: %d / %d m" % [r["metres"], r["length"]],
		"%s: %d / %d%s" % [str(r["gas_name"]).capitalize(), r["gas"], r["gas_total"], "   ★ all of it!" if r["gas"] >= r["gas_total"] and r["gas_total"] > 0 else ""],
		"Enemies beaten: %d" % r["enemies"],
		"XP: %d (distance %d, pickups and enemies %d%s)" % [r["xp"], r["xp_distance"], r["xp_items"], (", finish %d" % r["xp_finish"]) if r["finished"] else ""],
	]
	if r["no_hit"]:
		lines.append("Not a scratch!")
	for line in lines:
		v.add_child(UiTheme.label(line, 24, UiTheme.INK))
	if r["levels"] > 0:
		var lv := UiTheme.label("Level up! Level %d · spend your points in Character" % r["level"], 26, UiTheme.ORANGE, true)
		v.add_child(lv)
		Audio.play("level_up")
	elif not r["finished"]:
		v.add_child(UiTheme.label("Your XP is kept. Level up, raise your stats, try again!", 22, Color(0.35, 0.25, 0.15)))
	for a in r["achievements"]:
		v.add_child(UiTheme.label("Achievement: " + a, 22, Color(0.15, 0.45, 0.6), true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var next: String = run.next_stage_id()
	if r["finished"] and next != "" and SaveManager.is_stage_open(next):
		var nb := UiTheme.button("Next stage", func() -> void:
			Router.go("run", {"stage": next, "world_index": GameData.world_list().find(GameData.world_of_stage(next))}), 220)
		row.add_child(nb)
	row.add_child(UiTheme.button("Again", func() -> void: Router.go("run", Router.params), 180))
	if r["levels"] > 0 or SaveManager.free_points() > 0:
		row.add_child(UiTheme.button("Character", func() -> void: Router.go("character"), 220))
	row.add_child(UiTheme.button("Worlds", _to_map, 180))
	v.add_child(row)
	row.get_child(0).grab_focus.call_deferred()
	for b in get_children():
		if b is TouchScreenButton:
			b.visible = false
