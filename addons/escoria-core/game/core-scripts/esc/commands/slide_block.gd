# `slide_block object target [speed]`
#
# Moves `object` towards the position of `target`. This command is
# blocking.
#
# - *object*: Global ID of the object to move
# - *target*: Global ID of the target object
# - *speed*: The speed at which to slide in pixels per second (will default to
#   the speed configured on the `object`)
#
# **Warning** This command does not respect the room's navigation polygons, so
# `object` can be moved even when outside walkable areas.
#
# @ESC
extends SlideCommand
class_name SlideBlockCommand


# Run the command
func run(command_params: Array) -> int:
	var tween = _slide_object(
		escoria.object_manager.get_object(command_params[0]),
		escoria.object_manager.get_object(command_params[1]),
		command_params[2]
	)
	yield(tween, "tween_all_completed")
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	.interrupt()
