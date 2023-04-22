extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


func initialize(dialog_manager: ESCDialogManager) -> void:
	_dialog_manager = dialog_manager


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'interrupt'.")

	if _dialog_manager != null:
		if not _dialog_manager.is_connected("say_finished", self, "_on_say_finished"):
			_dialog_manager.connect("say_finished", self, "_on_say_finished", [], CONNECT_ONESHOT)

		_dialog_manager.interrupt()


func _on_say_finished() -> void:
	escoria.logger.trace(self, "Dialog State Machine: 'interrupt' -> 'finish'")
	emit_signal("finished", "finish")

