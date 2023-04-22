# Escoria dialog player
extends Node
class_name ESCDialogPlayer


# Emitted when an answer as chosem
#
# ##### Parameters
#
# - option: The dialog option that was chosen
signal option_chosen(option)

# Emitted when a say command finished
signal say_finished


# Reference to the currently playing "say" dialog manager
var _say_dialog_manager: ESCDialogManager = null

# Reference to the currently playing "choose" dialog manager
var _choose_dialog_manager: ESCDialogManager = null


# Register the dialog player and load the dialog resources
func _ready():
	if Engine.is_editor_hint():
		return

	escoria.dialog_player = self


# Make a character say some text
#
# #### Parameters
#
# - character: Character that is talking
# - type: UI to use for the dialog
# - text: Text to say
func say(character: String, type: String, text: String) -> void:
	if type == "":
		type = ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE
		)

	_determine_say_dialog_manager(type)

	if is_a_parent_of(_say_dialog_manager):
		remove_child(_say_dialog_manager)

	add_child(_say_dialog_manager)

	_say_dialog_manager.say(self, character, text, type)


# Display a list of choices
#
# #### Parameters
#
# - dialog: The dialog to start
# - type: The dialog chooser type to use (default: "simple")
func start_dialog_choices(dialog: ESCDialog, type: String = "simple"):
	_determine_choose_dialog_manager(type)

	if is_a_parent_of(_choose_dialog_manager):
		remove_child(_choose_dialog_manager)

	add_child(_choose_dialog_manager)

	_choose_dialog_manager.choose(self, dialog, type)


# Interrupt the currently running dialog
func interrupt() -> void:
	if is_instance_valid(_say_dialog_manager):
		_say_dialog_manager.interrupt()


# Loads the first dialog manager that supports the specified "say" type; otherwise,
# the engine throws an error and stops.
#
# #### Parameters
# - type: The type the dialog manager should support, e.g. "floating"
func _determine_say_dialog_manager(type: String) -> void:
	var dialog_manager: ESCDialogManager = null

	for _manager_class in ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	):
		if ResourceLoader.exists(_manager_class):
			var _manager: ESCDialogManager = load(_manager_class).new()
			if _manager.has_type(type):
				dialog_manager = _manager
			else:
				dialog_manager = null

	if not is_instance_valid(dialog_manager):
		escoria.logger.error(
			self,
			"No dialog manager called '%s' configured." % type
		)

	_say_dialog_manager = dialog_manager


# Loads the first dialog manager that supports the specified "choose" type; otherwise,
# the engine throws an error and stops.
#
# #### Parameters
# - type: The type the dialog manager should support, e.g. "simple"
func _determine_choose_dialog_manager(type: String) -> void:
	var dialog_manager: ESCDialogManager = null

	for _manager_class in ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	):
		if ResourceLoader.exists(_manager_class):
			var _manager: ESCDialogManager = load(_manager_class).new()
			if _manager.has_chooser_type(type):
				dialog_manager = _manager
			else:
				dialog_manager = null

	if not is_instance_valid(dialog_manager):
		escoria.logger.error(
			self,
			"No dialog manager called '%s' configured." % type
		)

	_choose_dialog_manager = dialog_manager
