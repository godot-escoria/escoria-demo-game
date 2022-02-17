# A base class for dialog plugins to work with Escoria
extends Control
class_name ESCDialogManager


# Emitted when the say function has completed showing the text
signal say_finished

# Emitted when the player has chosen an option
signal option_chosen(option)


# Check wether a specific type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# *Returns* Wether the type is supported or not
func has_type(type: String) -> bool:
	return false


# Check wether a specific chooser type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required chooser type
# *Returns* Wether the type is supported or not
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


# Present an option chooser to the player and sends the signal
# `option_chosen` with the chosen dialog option
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - dialog: Information about the dialog to display
func choose(dialog_player: Node, dialog: ESCDialog):
	pass


# Trigger running the dialog faster
func speedup():
	pass


# The say command has been interrupted, cancel the dialog display
func interrupt():
	pass
