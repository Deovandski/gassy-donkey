extends Screen
## Credits, as in the 2016 sketch: "thanks for playing my 1st game". Text comes from data/credits.json
## (the same file the website's play page reads).


func _ready() -> void:
	add_backdrop(true, true)
	add_back_button()
	var c: Dictionary = GameData.credits
	var v := column(18, 8)
	v.add_child(UiTheme.title("Credits", 60))
	var thanks := UiTheme.label(c.get("thanks", ""), 40, UiTheme.CYAN, true)
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(thanks)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	for item in c.get("credits", []):
		var row := UiTheme.label("%s:  %s" % [item["role"], item["who"]], 19, UiTheme.INK)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size = Vector2(840, 0)
		inner.add_child(row)
	var history := UiTheme.label(c.get("history", ""), 18, Color(0.35, 0.25, 0.15))
	history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history.custom_minimum_size = Vector2(840, 0)
	inner.add_child(history)
	var support := UiTheme.label(c.get("support", ""), 18, Color(0.35, 0.25, 0.15))
	support.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	support.custom_minimum_size = Vector2(840, 0)
	inner.add_child(support)
	v.add_child(Screen.centered(panel))
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 20)
	var links: Dictionary = c.get("links", {})
	row2.add_child(UiTheme.button("eBooks on Amazon", func() -> void: OS.shell_open(links.get("amazon", "")), 280))
	row2.add_child(UiTheme.button("#HusbandOutWorld", func() -> void: OS.shell_open(links.get("series", "")), 280))
	row2.add_child(UiTheme.button("Source code", func() -> void: OS.shell_open(links.get("source", "")), 280))
	v.add_child(row2)
