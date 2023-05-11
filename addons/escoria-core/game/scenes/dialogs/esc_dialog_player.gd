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


# Used when specifying dialog types in various methods
const DIALOG_TYPE_SAY = "say"

const DIALOG_TYPE_CHOOSE = "choose"


# Reference to the currently playing "say" dialog manager
var _say_dialog_manager: ESCDialogManager = null

# Reference to the currently playing "choose" dialog manager
var _choose_dialog_manager: ESCDialogManager = null

# Whether to use the "dialog box preservation" feature
var _block_say_enabled: bool = false


# Register the dialog player and load the dialog resources
func _ready():
	if Engine.is_editor_hint():
		return

	escoria.dialog_player = self


# Instructs the dialog manager to preserve the next dialog box used by a `say`
# command until a call to `disable_preserve_dialog_box` is made.
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `disable_preserve_dialog_box` being called, the result should be the
# same.
func enable_preserve_dialog_box() -> void:
	_block_say_enabled = true


# Instructs the dialog manager to no longer preserve the currently-preserved
# dialog box or to not preserve the next dialog box used by a `say` command
# (this is the default state).
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `enable_preserve_dialog_box` being called, the result should be the
# same.
func disable_preserve_dialog_box() -> void:
	_block_say_enabled = false
	_say_dialog_manager.disable_preserve_dialog_box()


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

	# We only need to remove the dialog manager from the scene tree if the dialog manager type
	# has changed since the last use of this method.
	_update_dialog_manager(DIALOG_TYPE_SAY, _say_dialog_manager, type)

	if _block_say_enabled:
		_say_dialog_manager.enable_preserve_dialog_box()

	_say_dialog_manager.say(self, character, text, type)


# Display a list of choices
#
# #### Parameters
#
# - dialog: The dialog to start
# - type: The dialog chooser type to use (default: "simple")
func start_dialog_choices(dialog: ESCDialog, type: String = "simple"):
	# We only need to remove the dialog manager from the scene tree if the dialog manager type
	# has changed since the last use of this method.
	_update_dialog_manager(DIALOG_TYPE_CHOOSE, _choose_dialog_manager, type)

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


# If necessary, updates the dialog manager for the specified dialog type.
#
# #### Parameters
#
# - dialog_type: The type of dialog that will be managed, e.g. "say" or "choose"
# - current_dialog_manager: The dialog manager currently being used (if any) for the specified
#   dialog type
# - dialog_manager_type: The dialog manager type specific to the dialog manager being requested
func _update_dialog_manager(dialog_type: String, current_dialog_manager: ESCDialogManager, \
	dialog_manager_type: String) -> void:

	if is_instance_valid(current_dialog_manager):
		if not current_dialog_manager.has_type(dialog_manager_type):
			if is_a_parent_of(current_dialog_manager):
				remove_child(current_dialog_manager)

			add_child(_determine_dialog_manager(dialog_type, dialog_manager_type))
	else:
		add_child(_determine_dialog_manager(dialog_type, dialog_manager_type))


# Sets the requested dialog manager type for the specified dialog function.
#
# #### Parameters
#
# - dialog_type: The type of dialog that will be managed, e.g. "say" or "choose"
# - dialog_manager_type: The dialog manager type specific to the dialog manager being requested
#
# *Returns* the newly-resolved dialog manager
func _determine_dialog_manager(dialog_type: String, dialog_manager_type: String) -> ESCDialogManager:
	if dialog_type == DIALOG_TYPE_SAY:
		_determine_say_dialog_manager(dialog_manager_type)
		return _say_dialog_manager
	elif dialog_type == DIALOG_TYPE_CHOOSE:
		_determine_choose_dialog_manager(dialog_manager_type)
		return _choose_dialog_manager

	# This line will never be hit as a failure above will result in an Escoria error
	return null
