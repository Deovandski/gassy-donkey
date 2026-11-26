extends Node2D
## Port of Assets/Scripts/FakePlanetMotion.cs (2016): rocks a planet one way for 10 seconds,
## then back the other way, so it looks like it turns.

@export var motion_speed := 1.0  ## degrees per second (FakePlanetMotion.motionSpeed)
var max_rotation_time := 10.0
var current_rotation_time := 0.0
var forward_rotation := true


func _process(delta: float) -> void:
	if current_rotation_time < max_rotation_time:
		var degrees := delta * motion_speed
		rotation += Unity.rot(degrees if forward_rotation else -degrees)
		current_rotation_time += delta
	else:
		forward_rotation = not forward_rotation
		current_rotation_time = 0.0
