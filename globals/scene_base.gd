extends Node

func _ready():
	get_node("/root/main").call_deferred("set_current_scene", self)
	pass

