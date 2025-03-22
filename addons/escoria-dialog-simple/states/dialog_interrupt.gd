extends State


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


func initialize(dialog_manager: ESCDialogManager) -> void:
	_dialog_manager = dialog_manager


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'interrupt'.")

	if _dialog_manager != null:
		if not _dialog_manager.say_finished.is_connected(_on_say_finished):
			_dialog_manager.say_finished.connect(_on_say_finished)

		_dialog_manager.interrupt()


func _on_say_finished() -> void:
	escoria.logger.trace(self, "Dialog State Machine: 'interrupt' -> 'finish'")
	finished.emit("finish")
