## `slide_block(object: String, target: String[, speed: Integer])`
##
## Moves `object` towards the position of `target`. This command is
## blocking.[br]
##[br]
## - *object*: Global ID of the object to move[br]
## - *target*: Global ID of the target object[br]
## - *speed*: The speed at which to slide in pixels per second (will default to
##   the speed configured on the `object`)[br]
##[br]
## **Warning** This command does not respect the room's navigation polygons, so
## `object` can be moved even when outside walkable areas.
##
## @ESC
extends SlideCommand
class_name SlideBlockCommand


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	var tween = _slide_object(
		escoria.object_manager.get_object(command_params[0]),
		escoria.object_manager.get_object(command_params[1]),
		command_params[2]
	)
	await tween.finished
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	super.interrupt()
