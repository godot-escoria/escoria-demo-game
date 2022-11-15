extends State
class_name DialogInterrupt


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


func initialize(dialog_manager: ESCDialogManager) -> void:
	_dialog_manager = dialog_manager


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'interrupt'.")

	if not _dialog_manager.is_connected("say_finished", self, "_on_say_finished"):
		_dialog_manager.connect("say_finished", self, "_on_say_finished", [], CONNECT_ONESHOT)

	if _dialog_manager != null:
		_dialog_manager.interrupt()


func _on_say_finished() -> void:
	escoria.logger.trace(self, "Dialog State Machine: 'interrupt' -> 'finish'")
	emit_signal("finished", "finish")

