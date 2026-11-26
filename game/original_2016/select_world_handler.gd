extends Camera2D
## Port of Assets/Scripts/SelectWorldHandler.cs (2016), which sat on the Main Camera.
## The Select World button jumps the camera up to the world selection; Escape (or Android's back button)
## jumps back to the main menu. Unity moved the camera instantly, with no slide, and so does this.

var world_selection_object: Node2D
var main_menu_object: Node2D
var is_viewing_world_section := false


func setup(world_selection: Node2D, main_menu: Node2D) -> void:
	world_selection_object = world_selection
	main_menu_object = main_menu
	if world_selection_object == null or main_menu_object == null:
		push_error("SelectWorldHandler Initialization Issue.")


func view_world_selection() -> void:
	position.y = world_selection_object.position.y
	is_viewing_world_section = true


func view_main_menu() -> void:
	# Unity copied the menu's y (0), not the camera's starting 4.78, so the menu sits a little higher after
	# coming back. Kept as it was.
	position.y = main_menu_object.position.y
	is_viewing_world_section = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_viewing_world_section:
		view_main_menu()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_viewing_world_section:
		view_main_menu()
