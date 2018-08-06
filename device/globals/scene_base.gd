extends Node

export(String, FILE, ".esc") var events_path = ""

func _ready():
	# XXX: Why is this call required?
	# Running the events when loading a game messes the game state completely, don't do it
	var run_events = not vm.loading_game
	main.call_deferred("set_current_scene", self, events_path, run_events)

