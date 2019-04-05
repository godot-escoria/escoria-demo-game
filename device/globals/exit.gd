extends "res://globals/trigger.gd"

func body_entered(body):
	# Entering an exit node runs the `:exit_scene` event
	if body is esc_type.PLAYER:
		if self.visible:
			run_event("exit_scene")

func body_exited(_body):
	# Do nothing when exiting an exit node. Usually this code should not be hit.
	return

func _ready():
	if not "exit_scene" in event_table:
		vm.report_errors("exit", [":exit_scene missing for " + self.name])

