## A base class for dialog plugins to work with Escoria
extends Control
class_name ESCDialogManager

## Emitted when the say function has completed showing the text
signal say_finished

## Emitted when text has just become fully visible
signal say_visible

## Emitted when the player has chosen an option
signal option_chosen(option)

## Checks whether a specific type is supported by the dialog plugin.[br]
## [br]
## #### Parameters[br]
## [br]
## - type: Required type.[br]
## [br]
## Returns whether the type is supported or not.
func has_type(type: String) -> bool:
	return false

## Checks whether a specific chooser type is supported by the dialog plugin.[br]
## [br]
## #### Parameters[br]
## [br]
## - type: Required chooser type.[br]
## [br]
## Returns whether the type is supported or not.
func has_chooser_type(type: String) -> bool:
	return false

## Outputs a text said by the item specified by the global id and emits
## `say_finished` after finishing displaying the text.[br]
## [br]
## #### Parameters[br]
## [br]
## - dialog_player: Node of the dialog player in the UI.[br]
## - global_id: Global id of the item that is speaking.[br]
## - text: Text to say, optional prefixed by a translation key separated[br]
##   by a ":".[br]
## - type: Type of dialog box to use.[br]
## - key: Translation key.
func say(dialog_player: Node, global_id: String, text: String, type: String, key: String):
	pass

## Instructs the dialog manager to preserve the next dialog box used by a
## `say` command until a call to `disable_preserve_dialog_box` is made.[br]
## [br]
## This method should be idempotent, i.e. if called after the first time and
## prior to `disable_preserve_dialog_box` being called, the result should be[br]
## the same.
func enable_preserve_dialog_box() -> void:
	pass

## Instructs the dialog manager to no longer preserve the currently-preserved
## dialog box or to not preserve the next dialog box used by a `say` command[br]
## (this is the default state).[br]
## [br]
## This method should be idempotent, i.e. if called after the first time and
## prior to `enable_preserve_dialog_box` being called, the result should be[br]
## the same.
func disable_preserve_dialog_box() -> void:
	pass

## Presents an option chooser to the player and sends the signal
## `option_chosen` with the chosen dialog option.[br]
## [br]
## #### Parameters[br]
## [br]
## - dialog_player: Node of the dialog player in the UI.[br]
## - dialog: Information about the dialog to display.[br]
## - type: The dialog chooser type to use.
func choose(dialog_player: Node, dialog: ESCDialog, type: String):
	pass

## Triggers running the dialogue faster.
func speedup():
	pass

## Triggers an instant finish of the current dialog.
func finish():
	pass

## The say command has been interrupted, cancel the dialog display.
func interrupt():
	pass

## To be called if voice audio has finished.
func voice_audio_finished():
	pass
