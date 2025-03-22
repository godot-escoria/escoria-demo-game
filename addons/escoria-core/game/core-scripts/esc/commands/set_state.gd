## `set_state object state [immediate]`[br]
## [br]
## Changes the state of `object` to the one specified.[br]
## This command is primarily used to play animations.[br]
## [br]
## If the specified object's associated animation player has an animation
## with the same name, that animation is also played.[br]
## [br]
## When the "state" of the object is set - for example, a door may be set
## to a "closed" state - this plays the matching "close" animation if one exists
## (to show the door closing in the game). When you re-enter the room (via a
## different entry), or restore a saved game, the state of the door object
## will be restored - showing the door as a closed door.[br]
## [br]
## #### Parameters[br]
## [br]
## - *object*: Global ID of the object whose state is to be changed[br]
## - *state*: Name of the state to be set[br]
## - *immediate*: If an animation for the state exists, specifies
##   whether it is to skip to the last frame. Can be `true` or `false`.[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name SetStateCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_BOOL],
		[null, null, false]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
		return false

	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]) as ESCObject).set_state(
		command_params[1],
		command_params[2]
	)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
