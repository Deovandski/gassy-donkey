extends Screen
## The finished game's main menu, laid out like the 2016 one (and the 2016 sketch: logo, Select World,
## Character, Achievements, Credits), over the same sky.


func _ready() -> void:
	back_to = ""
	add_backdrop()
	Audio.menu_music()
	var v := column(26, 10)

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 18)
	var logo := TextureRect.new()
	logo.texture = load("res://art/legacy/logo.png")
	logo.custom_minimum_size = Vector2(170, 170)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(logo)
	head.add_child(UiTheme.title(GameData.credits.get("name", "Gassy Donkey"), 104))
	v.add_child(head)

	var level := SaveManager.level()
	var bar := Progression.level_progress(int(SaveManager.data["xp"]), SaveManager.xp_table())
	var level_text := "Level %d" % level
	level_text += "   ·   %d / %d XP" % [bar.x, bar.y] if bar.y > 0 else "   ·   max level"
	var lvl := UiTheme.label(level_text, 28, UiTheme.CYAN, true)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lvl)
	var points := SaveManager.free_points()
	if points > 0:
		var p := UiTheme.label("%d stat point%s to spend in Character!" % [points, "" if points == 1 else "s"], 24, UiTheme.PEACH)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(p)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16 if points > 0 else 44)
	v.add_child(spacer)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 18)
	var play := UiTheme.button("Select World", func() -> void: Router.go("world_select"), 300)
	grid.add_child(play)
	grid.add_child(UiTheme.button("Character", func() -> void: Router.go("character"), 300))
	grid.add_child(UiTheme.button("Achievements", func() -> void: Router.go("achievements"), 300))
	grid.add_child(UiTheme.button("Credits", func() -> void: Router.go("credits"), 300))
	v.add_child(Screen.centered(grid))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	var settings := UiTheme.button("Settings", func() -> void: Router.go("settings"), 300)
	settings.add_theme_font_size_override("font_size", 22)
	row.add_child(settings)
	var old := UiTheme.button("Play the 2016 original", func() -> void: Router.go("original_2016"), 300)
	old.add_theme_font_size_override("font_size", 22)
	row.add_child(old)
	v.add_child(row)
	play.grab_focus.call_deferred()
