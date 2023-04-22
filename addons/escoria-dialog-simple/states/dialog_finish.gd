extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


# Owning dialog player
var _dialog_player


func initialize(dialog_player) -> void:
	_dialog_player = dialog_player


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'finish'.")


func update(_delta):
	escoria.logger.trace(self, "Dialog State Machine: 'finish' -> 'idle'")
	emit_signal("finished", "idle")
	_dialog_player.emit_signal("say_finished")
