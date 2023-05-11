# A base class for dialog plugins to work with Escoria
extends Control
class_name ESCDialogManager


# Emitted when the say function has completed showing the text
signal say_finished

# Emitted when text has just become fully visible
signal say_visible

# Emitted when the player has chosen an option
signal option_chosen(option)


# Check whether a specific type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# *Returns* Whether the type is supported or not
func has_type(type: String) -> bool:
	return false


# Check whether a specific chooser type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required chooser type
# *Returns* Whether the type is supported or not
func has_chooser_type(type: String) -> bool:
	return false


# Output a text said by the item specified by the global id. Emit
# `say_finished` after finishing displaying the text.
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - global_id: Global id of the item that is speaking
# - text: Text to say, optional prefixed by a translation key separated
#   by a ":"
# - type: Type of dialog box to use
func say(dialog_player: Node, global_id: String, text: String, type: String):
	pass


# Instructs the dialog manager to preserve the next dialog box used by a `say`
# command until a call to `disable_preserve_dialog_box` is made.
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `disable_preserve_dialog_box` being called, the result should be the
# same.
func enable_preserve_dialog_box() -> void:
	pass


# Instructs the dialog manager to no longer preserve the currently-preserved
# dialog box or to not preserve the next dialog box used by a `say` command
# (this is the default state).
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `enable_preserve_dialog_box` being called, the result should be the
# same.
func disable_preserve_dialog_box() -> void:
	pass


# Present an option chooser to the player and sends the signal
# `option_chosen` with the chosen dialog option
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - dialog: Information about the dialog to display
# - type: The dialog chooser type to use
func choose(dialog_player: Node, dialog: ESCDialog, type: String):
	pass


# Trigger running the dialogue faster
func speedup():
	pass


# Trigger an instant finish of the current dialog
func finish():
	pass


# The say command has been interrupted, cancel the dialog display
func interrupt():
	pass


# To be called if voice audio has finished.
func voice_audio_finished():
	pass
