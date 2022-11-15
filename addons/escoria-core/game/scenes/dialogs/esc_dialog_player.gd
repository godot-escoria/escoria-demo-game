# Escoria dialog player
extends StateMachine
class_name ESCDialogPlayer


# Emitted when an answer as chosem
#
# ##### Parameters
#
# - option: The dialog option that was chosen
signal option_chosen(option)

# Emitted when a say command finished
signal say_finished


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


# Register the dialog player and load the dialog resources
func _ready():
	if Engine.is_editor_hint():
		return

	escoria.dialog_player = self

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
		"visible": DialogVisible.new(),
		"finish": DialogFinish.new(),
		"interrupt": DialogInterrupt.new(),
		"choices": DialogChoices.new(),
	}

	# This state needs a reference to this class.
	states_map["finish"].initialize(self)


# Adds any created states into the state machine as children.
func _add_states_to_machine() -> void:
	for key in states_map:
		add_child(states_map[key])


# Make a character say some text
#
# #### Parameters
#
# - character: Character that is talking
# - type: UI to use for the dialog
# - text: Text to say
func say(character: String, type: String, text: String) -> void:
	states_map["say"].initialize(character, type, text)
	_change_state("say")


# Called when a dialog line is to be sped up.
func speedup() -> void:
	_change_state("say_fast")


# Display a list of choices
#
# #### Parameters
#
# - dialog: The dialog to start
func start_dialog_choices(dialog: ESCDialog, type: String = "simple"):
	states_map["choices"].initialize(self, dialog, type)
	_change_state("choices")


# Interrupt the currently running dialog
func interrupt() -> void:
	_change_state("interrupt")


# Since the dialog manager is determined when a `say` command is performed and
# other states need to know which one was picked, we notify the necessary states
# via this method.
func _on_dialog_manager_set(dialog_manager: ESCDialogManager) -> void:
	_dialog_manager = dialog_manager
	states_map["say_fast"].initialize(dialog_manager)
	states_map["visible"].initialize(dialog_manager)
	states_map["interrupt"].initialize(dialog_manager)
