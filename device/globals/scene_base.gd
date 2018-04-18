extends Node

export(String, FILE, ".esc") var events_path = ""

func _ready():
	var start_pos_node = null
	main.call_deferred("set_current_scene", self, start_pos_node, events_path)

