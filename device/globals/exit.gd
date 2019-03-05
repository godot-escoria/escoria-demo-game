extends "res://globals/trigger.gd"

func stopped_at(pos):
	# TextureRect exits run this code
#	if self is Control and get_global_rect().has_point(pos):
#		if self.visible:
#			run_event("exit_scene")
	pass

func body_entered(body):
	# Entering an exit node runs the `:exit_scene` event
	if body is esc_type.PLAYER:
		if self.visible:
			run_event("exit_scene")

func body_exited(body):
	# Do nothing when exiting an exit node. Usually this code should not be hit.
	return

func _ready():
	add_to_group("exit")

	if not "exit_scene" in event_table:
		vm.report_errors("exit", [":exit_scene missing for " + self.name])

