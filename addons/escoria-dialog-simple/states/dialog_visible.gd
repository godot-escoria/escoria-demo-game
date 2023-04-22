extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


func initialize(dialog_manager: ESCDialogManager) -> void:
	_dialog_manager = dialog_manager


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'visible'.")

	if not _dialog_manager.is_connected("say_finished", self, "_on_say_finished"):
		_dialog_manager.connect("say_finished", self, "_on_say_finished", [], CONNECT_ONESHOT)


func handle_input(_event):
	if _event is InputEventMouseButton and _event.pressed:
		if escoria.inputs_manager.input_mode != \
			escoria.inputs_manager.INPUT_NONE:

			if _dialog_manager.is_connected("say_finished", self, "_on_say_finished"):
				_dialog_manager.disconnect("say_finished", self, "_on_say_finished")

			emit_signal("finished", "interrupt")
			get_tree().set_input_as_handled()


# Handles the end of a say function after it has emitted say_finished.
func _on_say_finished():
	escoria.logger.trace(self, "Dialog State Machine: 'visible' -> 'finish'")
	emit_signal("finished", "finish")
