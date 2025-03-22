## Base class for all dialog options implementations
extends Control
class_name ESCDialogOptionsChooser

## Emitted when an option is chosen.[br]
## [br]
## #### Parameters[br]
## [br]
## - option: The dialog option that was chosen.
signal option_chosen(option)

## The dialog to show
var dialog: ESCDialog

## Sets the dialog used for the chooser.[br]
## [br]
## #### Parameters[br]
## [br]
## - new_dialog: Dialog to set.
func set_dialog(new_dialog: ESCDialog) -> void:
	self.dialog = new_dialog

## Shows the dialog chooser UI.
func show_chooser() -> void:
	escoria.logger.error(
		self,
		"Dialog chooser does not implement the show method."
	)

## Hides the dialog chooser UI.
func hide_chooser() -> void:
	escoria.logger.error(
		self,
		"Dialog chooser does not implement the hide method."
	)
