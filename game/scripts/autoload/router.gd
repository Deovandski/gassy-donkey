extends Node
## Changes screens, and picks the first screen.
##
## On the website, /play/#original-2016 opens the 2016 Unity port straight away; /play/ opens the finished game.
## Developer options (after `--` on the command line, see docs/BUILDING.md):
##   --scene=<name>          open this screen first (a key of SCENES)
##   --screenshot=<file.png> save a picture of the screen after --frames=<n> frames (default 90), then quit
##   --param=<key>:<value>   pass a setting to the first screen (for example world:amazon, stage:2)

const SCENES := {
	"main_menu": "res://scenes/main_menu.tscn",
	"original_2016": "res://original_2016/original_2016.tscn",
	"world_select": "res://scenes/world_select.tscn",
	"character": "res://scenes/character.tscn",
	"achievements": "res://scenes/achievements.tscn",
	"credits": "res://scenes/credits.tscn",
	"settings": "res://scenes/settings.tscn",
	"run": "res://scenes/run.tscn",
	"tests": "res://tests/run_tests.tscn",  # developer only: not in exports
}

## Settings for the screen being opened (for example which world and stage to run).
var params := {}
var dev := {}
var _frames_left := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		if parts.size() == 2:
			if parts[0] == "param":
				var kv := parts[1].split(":", true, 1)
				params[kv[0]] = kv[1] if kv.size() > 1 else ""
			else:
				dev[parts[0]] = parts[1]
	if dev.has("screenshot"):
		_frames_left = int(dev.get("frames", "90"))
	SaveManager.achievement_unlocked.connect(_on_achievement)


## A small banner when an achievement unlocks, on any screen.
func _on_achievement(id: String) -> void:
	var a := GameData.achievement(id)
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var panel := PanelContainer.new()
	panel.theme = UiTheme.theme()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.position.y -= 24
	var l := UiTheme.label("Achievement: %s" % a.get("name", id), 26, UiTheme.INK, true)
	panel.add_child(l)
	layer.add_child(panel)
	Audio.play("achievement")
	var tw := panel.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(panel, "modulate:a", 0.0, 0.6)
	tw.tween_callback(layer.queue_free)


## The screen to open first: from the command line, the web address, or the main menu.
func first_scene() -> String:
	if dev.has("scene"):
		return dev["scene"]
	if OS.has_feature("web"):
		var hash := str(JavaScriptBridge.eval("window.location.hash", true))
		if hash.begins_with("#original-2016") or hash.begins_with("#2016"):
			return "original_2016"
	return "main_menu"


func go(scene: String, new_params := {}) -> void:
	if not SCENES.has(scene):
		push_error("Router: no screen called %s" % scene)
		return
	params = new_params
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(SCENES[scene])


func _process(_delta: float) -> void:
	if _frames_left < 0:
		return
	_frames_left -= 1
	if _frames_left == 0:
		var path: String = dev["screenshot"]
		var img := get_viewport().get_texture().get_image()
		img.save_png(path)
		print("screenshot: ", path, " ", img.get_size())
		get_tree().quit()
