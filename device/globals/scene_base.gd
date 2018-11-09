extends Node

export(String, FILE, ".esc") var events_path = ""

func _ready():
	# Call `set_current_scene` only when not loading the game, because doing so
	# when loading the game causes glitches in the events when `set_scene` also
	# calls `set_current_scene`.
	var run_events = not vm.loading_game
	if run_events:
		main.call_deferred("set_current_scene", self, run_events)

