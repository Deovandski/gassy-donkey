extends Node2D
## Port of Assets/Scripts/RotateStar.cs (2016): spins a sprite forever around its own centre.
## Used by the Sun and the starfield background.

@export var rotation_speed := 2.0  ## degrees per second (RotateStar.rotationSpeed)
@export var forward_rotation := true  ## true: counter-clockwise, as Unity's transform.forward


func _process(delta: float) -> void:
	var degrees := delta * rotation_speed
	rotation += Unity.rot(degrees if forward_rotation else -degrees)
