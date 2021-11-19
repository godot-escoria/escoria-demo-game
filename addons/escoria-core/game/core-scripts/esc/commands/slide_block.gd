# `slide object target [speed]`
#
# Moves the object towards the position of the target object, This command is
# blocking. 
#
# - *object*: Global ID of the object to move
# - *target*: Global ID of the target object
# - *speed*: Speed for the movement (defaults to the object's default speed)
#
# **Warning** This command does not respect the room's navigation polygons, so
# so the object can be moved even outside walkable areas.
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
