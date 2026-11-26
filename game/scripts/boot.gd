extends Node
## The first screen: hands over to the right one (Router.first_scene()).


func _ready() -> void:
	Router.go(Router.first_scene(), Router.params)
