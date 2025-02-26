extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'idle'.")
