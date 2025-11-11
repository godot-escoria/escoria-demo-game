## Base class for all dialog options implementations
extends Control
class_name ESCDialogOptionsChooser

## Emitted when an option is chosen.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |option|`Variant`|The dialog option that was chosen.|yes|[br]
## [br]
signal option_chosen(option)

## The dialog to show
var dialog: ESCDialog

## Sets the dialog used for the chooser.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |new_dialog|`ESCDialog`|Dialog to set.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_dialog(new_dialog: ESCDialog) -> void:
	self.dialog = new_dialog

## Shows the dialog chooser UI.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func show_chooser() -> void:
	escoria.logger.error(
		self,
		"Dialog chooser does not implement the show method."
	)

## Hides the dialog chooser UI.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func hide_chooser() -> void:
	escoria.logger.error(
		self,
		"Dialog chooser does not implement the hide method."
	)
