extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


func initialize(dialog_manager: ESCDialogManager) -> void:
	_dialog_manager = dialog_manager


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'say_fast'.")

	if escoria.inputs_manager.input_mode != \
		escoria.inputs_manager.INPUT_NONE and \
		_dialog_manager != null:

		if not _dialog_manager.say_visible.is_connected(_on_say_visible):
			_dialog_manager.say_visible.connect(_on_say_visible)

		_dialog_manager.speedup()
	else:
		escoria.logger.error(self, "Illegal state.")


func _on_say_visible() -> void:
	escoria.logger.trace(self, "Dialog State Machine: 'say_fast' -> 'visible'")
	finished.emit("visible")
