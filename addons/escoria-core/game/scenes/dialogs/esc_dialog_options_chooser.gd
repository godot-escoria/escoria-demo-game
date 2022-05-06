# Base class for all dialog options implementations
extends Control
class_name ESCDialogOptionsChooser


# An option was chosen
#
# ##### Parameters
#
# - option: The dialog option that was chosen
signal option_chosen(option)


# The dialog to show
var dialog: ESCDialog


# Set the dialog used for the chooser
#
# #### Parameters
#
# - new_dialog: Dialog to set
func set_dialog(new_dialog: ESCDialog) -> void:
	self.dialog = new_dialog


# Show the dialog chooser UI
func show_chooser() -> void:
	escoria.logger.error(
		self,
		"Dialog chooser did not implement the show method."
	)


# Hide the dialog chooser UI
func hide_chooser() -> void:
	escoria.logger.error(
		self,
		"Dialog chooser did not implement the hide method."
	)
