# `slide_block object1 object2 [speed]`
#
# Moves object1 towards the position of object2, at the speed determined by 
# object1's "speed" property, unless overridden. This command is blocking. 
# It does not respect the room's navigation polygons, so you can move items 
# where the player can't walk.
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
