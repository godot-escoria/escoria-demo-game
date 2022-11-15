# A simple dialog manager for Escoria
extends ESCDialogManager
class_name ESCDialogSimple


# The currently running player
var _type_player: Node = null

# Reference to the dialog player
var _dialog_player: Node = null


# Check whether a specific type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# *Returns* Whether the type is supported or not
func has_type(type: String) -> bool:
	return true if type in ["floating", "avatar"] else false


# Check whether a specific chooser type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required chooser type
# *Returns* Whether the type is supported or not
func has_chooser_type(type: String) -> bool:
	return true if type == "simple" else false


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
	_dialog_player = dialog_player

	if type == "floating":
		_type_player = preload(\
			"res://addons/escoria-dialog-simple/types/floating.tscn"\
		).instance()
	else:
		_type_player = preload(\
			"res://addons/escoria-dialog-simple/types/avatar.tscn"\
		).instance()

	_type_player.connect("say_finished", self, "_on_say_finished", [], CONNECT_ONESHOT)
	_type_player.connect("say_visible", self, "_on_say_visible", [], CONNECT_ONESHOT)

	_dialog_player.add_child(_type_player)
	_type_player.say(global_id, text)
#	yield(_type_player, "say_finished")
#	if _dialog_player.get_children().has(_type_player):
#		_dialog_player.remove_child(_type_player)
#		emit_signal("say_finished")


func _on_say_finished():
	if _dialog_player.get_children().has(_type_player):
		_dialog_player.remove_child(_type_player)
		emit_signal("say_finished")


func _on_say_visible():
	emit_signal("say_visible")


# Present an option chooser to the player and sends the signal
# `option_chosen` with the chosen dialog option
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - dialog: Information about the dialog to display
func choose(dialog_player: Node, dialog: ESCDialog):
	var chooser = preload(\
		"res://addons/escoria-dialog-simple/chooser/simple.tscn"\
	).instance()
	dialog_player.add_child(chooser)
	chooser.set_dialog(dialog)
	chooser.show_chooser()
	var option = yield(chooser, "option_chosen")
	dialog_player.remove_child(chooser)
	emit_signal("option_chosen", option)


# Trigger running the dialog faster
func speedup():
	if _type_player != null:
		_type_player.speedup()


# The say command has been interrupted, cancel the dialog display
func interrupt():
	if _dialog_player.get_children().has(_type_player):
		_dialog_player.remove_child(_type_player)
		emit_signal("say_finished")
