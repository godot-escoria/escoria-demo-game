## A base class for dialog plugins to work with Escoria
## @MANAGER
class_name ESCDialogManager
extends Control

## Emitted when the say function has completed showing the text[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
signal say_finished

## Emitted when text has just become fully visible[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
signal say_visible

## Emitted when the player has chosen an option[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |option|`Variant`|Dialog option chosen by the player.|yes|[br]
## [br]
signal option_chosen(option)

## Checks whether a specific type is supported by the dialog plugin.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |type|`String`|Required type.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns whether the type is supported or not. (`bool`)
func has_type(_type: String) -> bool:
	return false

## Checks whether a specific chooser type is supported by the dialog plugin.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |type|`String`|Required chooser type.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns whether the type is supported or not. (`bool`)
func has_chooser_type(_type: String) -> bool:
	return false

## Outputs a text said by the item specified by the global id and emits `say_finished` after finishing displaying the text.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |dialog_player|`Node`|Node of the dialog player in the UI.|yes|[br]
## |global_id|`String`|Global id of the item that is speaking.|yes|[br]
## |text|`String`|Text to say, optional prefixed by a translation key separated by a ":".|yes|[br]
## |type|`String`|Type of dialog box to use.|yes|[br]
## |key|`String`|Translation key.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func say(_dialog_player: Node, _global_id: String, _text: String, _type: String, _key: String):
	pass

## Instructs the dialog manager to preserve the next dialog box used by a `say` command until a call to `disable_preserve_dialog_box` is made. This method should be idempotent, i.e. if called after the first time and prior to `disable_preserve_dialog_box` being called, the result should be the same.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func enable_preserve_dialog_box() -> void:
	pass

## Instructs the dialog manager to no longer preserve the currently-preserved dialog box or to not preserve the next dialog box used by a `say` command (this is the default state). This method should be idempotent, i.e. if called after the first time and prior to `enable_preserve_dialog_box` being called, the result should be the same.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func disable_preserve_dialog_box() -> void:
	pass

## Presents an option chooser to the player and sends the signal `option_chosen` with the chosen dialog option.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |dialog_player|`Node`|Node of the dialog player in the UI.|yes|[br]
## |dialog|`ESCDialog`|Information about the dialog to display.|yes|[br]
## |type|`String`|The dialog chooser type to use.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func choose(_dialog_player: Node, _dialog: ESCDialog, _type: String):
	pass

## Triggers running the dialogue faster.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func speedup():
	pass

## Triggers an instant finish of the current dialog.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func finish():
	pass

## The say command has been interrupted, cancel the dialog display.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	pass

## To be called if voice audio has finished.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func voice_audio_finished():
	pass
