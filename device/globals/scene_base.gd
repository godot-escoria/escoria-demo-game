extends Node

func _ready():
	main.call_deferred("set_current_scene", self)


