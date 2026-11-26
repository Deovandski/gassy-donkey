extends Screen
## Achievements, drawn like the 2016 sketch: an icon, a progress bar and what it's for.


func _ready() -> void:
	add_backdrop(false, false)
	add_back_button()
	var title := UiTheme.title("Achievements", 60)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.position.y = 14
	add_child(title)
	var got := 0
	for a in GameData.achievements:
		got += 1 if SaveManager.is_unlocked(a["id"]) else 0
	var count := UiTheme.label("%d of %d" % [got, GameData.achievements.size()], 24, UiTheme.CYAN, true)
	count.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	count.position = Vector2(-150, 30)
	add_child(count)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 120
	panel.offset_right = -120
	panel.offset_top = 104
	panel.offset_bottom = -20
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var medal: Texture2D = load("res://art/new/medal.png")
	for a in GameData.achievements:
		var unlocked := SaveManager.is_unlocked(a["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var icon := TextureRect.new()
		icon.texture = medal
		icon.custom_minimum_size = Vector2(48, 58)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color.WHITE if unlocked else Color(0.2, 0.2, 0.2, 0.45)
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 0)
		var name_text: String = a["name"]
		if unlocked:
			name_text += "   (%s)" % SaveManager.data["achievements"][a["id"]]
		text.add_child(UiTheme.label(name_text, 24, UiTheme.INK, true))
		text.add_child(UiTheme.label(a["about"], 18, Color(0.3, 0.22, 0.15)))
		row.add_child(text)
		var p := SaveManager.achievement_progress(a)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(200, 26)
		bar.max_value = p.y
		bar.value = p.x
		bar.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = UiTheme.ORANGE
		fill.set_corner_radius_all(8)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.15)
		bg.set_corner_radius_all(8)
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", bg)
		var right := VBoxContainer.new()
		right.alignment = BoxContainer.ALIGNMENT_CENTER
		right.add_child(bar)
		var n := UiTheme.label("%d / %d" % [p.x, p.y], 16, Color(0.3, 0.22, 0.15))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right.add_child(n)
		row.add_child(right)
		list.add_child(row)
