class_name Screen
extends Control
## Base for the finished game's menu screens: full-window, the game's theme, the 2016 sky behind,
## and Escape (or Android's back button) goes back.

const Backdrop := preload("res://scripts/ui/space_backdrop.gd")

## Where Escape / back goes; empty means nowhere.
var back_to := "main_menu"


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.theme()


func add_backdrop(sun := true, vessel := true) -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	var b := Node2D.new()
	b.set_script(Backdrop)
	b.show_sun = sun
	b.show_vessel = vessel
	layer.add_child(b)


## A back button in the top-left corner.
func add_back_button() -> Button:
	var b := UiTheme.button("‹ Back", func() -> void: Router.go(back_to), 160)
	b.position = Vector2(20, 18)
	add_child(b)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if back_to != "" and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Router.go(back_to)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and back_to != "":
		Router.go(back_to)


## A centred column for a screen's content.
func column(top := 110.0, separation := 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = top
	v.offset_bottom = -20
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_theme_constant_override("separation", separation)
	add_child(v)
	return v


static func centered(node: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.add_child(node)
	return c
