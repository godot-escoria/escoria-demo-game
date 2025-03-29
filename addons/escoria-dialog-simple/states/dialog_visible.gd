extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


func initialize(dialog_manager: ESCDialogManager) -> void:
	_dialog_manager = dialog_manager


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'visible'.")

	if not _dialog_manager.say_finished.is_connected(_on_say_finished):
		_dialog_manager.say_finished.connect(_on_say_finished)


func handle_input(_event):
	if _event is InputEventMouseButton and _event.pressed:
		if escoria.inputs_manager.input_mode != \
			escoria.inputs_manager.INPUT_NONE:

			if _dialog_manager.say_finished.is_connected(_on_say_finished):
				_dialog_manager.say_finished.disconnect(_on_say_finished)

			finished.emit("interrupt")
			get_viewport().set_input_as_handled()


# Handles the end of a say function after it has emitted say_finished.
func _on_say_finished():
	escoria.logger.trace(self, "Dialog State Machine: 'visible' -> 'finish'")
	finished.emit("finish")
