extends Screen
## The Character menu from the 2016 design: "each level gives the player one point to spend in health,
## farting power, jump power and head attack power". Five boxes per stat, as in the sketch.

const ORDER := ["health", "fart", "jump", "headbutt"]

var _rows: VBoxContainer
var _points: Label
var _donkey: AnimatedSprite2D


func _ready() -> void:
	add_backdrop(false, false)
	add_back_button()
	var title := UiTheme.title("Character", 60)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.position.y = 14
	add_child(title)

	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 9.0)
	for i in range(1, 5):
		frames.add_frame("default", load("res://art/legacy/donkey/run_%d.png" % i))
	_donkey = AnimatedSprite2D.new()
	_donkey.sprite_frames = frames
	_donkey.scale = Vector2(1.05, 1.05)
	add_child(_donkey)
	_donkey.play()

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.custom_minimum_size = Vector2(680, 520)
	panel.position = Vector2(-720, -250)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	_points = UiTheme.label("", 30, UiTheme.INK, true)
	v.add_child(_points)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	v.add_child(_rows)
	get_viewport().size_changed.connect(_layout)
	_layout()
	refresh()


func _layout() -> void:
	var size := get_viewport_rect().size
	_donkey.position = Vector2(size.x * 0.2, size.y * 0.55)


func refresh() -> void:
	for c in _rows.get_children():
		c.queue_free()
	var level := SaveManager.level()
	var points := SaveManager.free_points()
	_points.text = "Level %d   ·   %d point%s to spend" % [level, points, "" if points == 1 else "s"]
	var defs: Dictionary = GameData.progression["stats"]
	var stat_max := int(GameData.progression.get("stat_max", 5))
	for key in ORDER:
		var rank := int(SaveManager.stats()[key])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var text := VBoxContainer.new()
		text.custom_minimum_size = Vector2(300, 0)
		text.add_theme_constant_override("separation", 0)
		text.add_child(UiTheme.label(defs[key]["name"], 26, UiTheme.INK, true))
		var about := UiTheme.label(defs[key]["about"], 16, Color(0.3, 0.22, 0.15))
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		about.custom_minimum_size = Vector2(300, 0)
		text.add_child(about)
		row.add_child(text)
		for i in stat_max:
			var box := Panel.new()
			box.custom_minimum_size = Vector2(36, 36)
			var sb := StyleBoxFlat.new()
			sb.bg_color = UiTheme.ORANGE if i < rank else Color(1, 1, 1, 0.4)
			sb.set_border_width_all(3)
			sb.border_color = UiTheme.INK
			sb.set_corner_radius_all(6)
			box.add_theme_stylebox_override("panel", sb)
			row.add_child(Screen.centered(box))
		var plus := UiTheme.button("+", func() -> void:
			if SaveManager.raise_stat(key):
				Audio.play("level_up", 1.3)
				refresh(), 64)
		plus.disabled = points <= 0 or rank >= stat_max
		plus.name = "Plus_" + key
		row.add_child(plus)
		_rows.add_child(row)
