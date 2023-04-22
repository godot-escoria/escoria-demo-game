extends "res://addons/escoria-dialog-simple/patterns/state_machine/state_machine.gd"


func _init():
	_create_states()
	_add_states_to_machine()

	states_map["say"].connect("dialog_manager_set", self, "_on_dialog_manager_set")

	current_state_name = "idle"
	START_STATE = states_map[current_state_name]

	initialize(START_STATE)


# Creates the states for this state machine.
func _create_states() -> void:
	states_map = {
		"idle": DialogIdle.new(),
		"say": DialogSay.new(),
		"say_fast": DialogSayFast.new(),
		"say_finish": DialogSayFinish.new(),
		"visible": DialogVisible.new(),
		"finish": DialogFinish.new(),
		"interrupt": DialogInterrupt.new(),
		"choices": DialogChoices.new(),
	}


# Adds any created states into the state machine as children.
func _add_states_to_machine() -> void:
	for key in states_map:
		add_child(states_map[key])


# Since the dialog manager is determined when a `say` command is performed and
# other states need to know which one was picked, we notify the necessary states
# via this method.
func _on_dialog_manager_set(dialog_manager: ESCDialogManager) -> void:
	states_map["say_fast"].initialize(dialog_manager)
	states_map["say_finish"].initialize(dialog_manager)
	states_map["visible"].initialize(dialog_manager)
	states_map["interrupt"].initialize(dialog_manager)
