class_name Unity
## Helpers for the 2016 port: Unity units, positions and sprite sizes in Godot.
##
## MainGame.unity used an orthographic camera with size 50, so the screen was 100 Unity units tall.
## The Godot project is 720 pixels tall, so one Unity unit is 7.2 pixels. Unity's y axis points up and
## Godot's points down, and Unity's positive rotation is counter-clockwise where Godot's is clockwise.

## Pixels per Unity unit (720 px / 100 units).
const K := 7.2
## The game's copies of the 2016 sprites are half size (tools/import_legacy_art.py).
const HALF := 2.0
## Unity imported every 2016 sprite at 100 pixels per unit.
const PIXELS_PER_UNIT := 100.0


## A Unity world position (x, y) as a Godot position.
static func pos(x: float, y: float) -> Vector2:
	return Vector2(x, -y) * K


## The Godot scale for a sprite whose Unity (world) scale is `unity_scale`.
static func sprite_scale(unity_scale: float) -> Vector2:
	return Vector2.ONE * unity_scale * K * HALF / PIXELS_PER_UNIT


## A Unity rotation around z (degrees, counter-clockwise) as a Godot rotation (radians, clockwise).
static func rot(degrees: float) -> float:
	return -deg_to_rad(degrees)
