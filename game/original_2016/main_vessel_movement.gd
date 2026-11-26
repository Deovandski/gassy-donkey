extends Node2D
## Port of Assets/Scripts/MainVesselMovement.cs (2016): flies the vessel across the main menu, then puts it
## back where it started once it has travelled max_travel_distance, and repeats.
##
## Unity moved it with transform.Translate(Vector2.up), which is along the sprite's nose; the vessel is
## turned 90 degrees, so its nose points left. Distances are in Unity units.

@export var travel_direction := "left"
@export var vessel_speed := 25.0  ## Unity units per second
@export var max_travel_distance := 300.0  ## Unity units
var distance_traveled := 0.0


func _process(delta: float) -> void:
	var current_position := position
	if distance_traveled >= max_travel_distance or distance_traveled <= -max_travel_distance:
		if travel_direction == "left":
			current_position.x -= distance_traveled * Unity.K
		else:
			current_position.x += distance_traveled * Unity.K
		distance_traveled = 0.0
		position = current_position
	else:
		# Translate(Vector2.up) in the sprite's own space: "up" is where its nose points.
		var nose := Vector2.UP.rotated(rotation)
		if travel_direction == "left":
			position += nose * vessel_speed * Unity.K * delta
		else:
			position -= nose * vessel_speed * Unity.K * delta
	distance_traveled += (position.x - current_position.x) / Unity.K
