extends Screen
## Sound volumes, the on-screen touch buttons, and resetting progress.


func _ready() -> void:
	add_backdrop(false, false)
	add_back_button()
	var v := column(20, 18)
	v.add_child(UiTheme.title("Settings", 60))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 18)
	panel.add_child(inner)
	inner.add_child(_slider("Music", "music"))
	inner.add_child(_slider("Sound effects", "sfx"))
	var touch := CheckButton.new()
	touch.text = "Show the touch buttons while running"
	touch.button_pressed = bool(SaveManager.setting("touch_buttons"))
	touch.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("touch_buttons", on))
	inner.add_child(touch)
	var controls := UiTheme.label(
		"Keyboard: Space / W / ↑ jump (twice: double jump up a level) · S / ↓ drop a level · A / ← / Z fart · D / → / X headbutt · P or Esc pause.\nTouch: tap the right side to jump, swipe down to drop, the left buttons fart and headbutt.",
		18, Color(0.3, 0.22, 0.15))
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.custom_minimum_size = Vector2(660, 0)
	inner.add_child(controls)
	var reset := UiTheme.button("Reset all progress", _confirm_reset, 320)
	inner.add_child(reset)
	v.add_child(Screen.centered(panel))


func _slider(text: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var l := UiTheme.label(text, 26, UiTheme.INK, true)
	l.custom_minimum_size = Vector2(240, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 1
	s.step = 0.05
	s.value = float(SaveManager.setting(key))
	s.custom_minimum_size = Vector2(380, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(value: float) -> void: SaveManager.set_setting(key, value))
	if key == "sfx":
		s.drag_ended.connect(func(_changed: bool) -> void: Audio.fart())
	row.add_child(s)
	return row


func _confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Start over? Your level, stats, stages and achievements will be wiped.\nThis can't be undone."
	dialog.ok_button_text = "Wipe it"
	dialog.confirmed.connect(func() -> void:
		SaveManager.reset()
		Router.go("main_menu"))
	add_child(dialog)
	dialog.popup_centered()
