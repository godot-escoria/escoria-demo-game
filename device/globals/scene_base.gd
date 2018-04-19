extends Node

export(String, FILE, ".esc") var events_path = ""

func _ready():
	main.call_deferred("set_current_scene", self, events_path)

