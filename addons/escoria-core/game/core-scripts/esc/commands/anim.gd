## `anim(object: String, name: String[, reverse: Boolean])`
##
## Executes the animation specified in "name" on "object" without blocking.
## The next command in the event will be executed immediately after the
## animation is started.[br]
##[br]
## **Parameters**[br]
##[br]
## * *object*: Global ID of the object with the animation[br]
## * *name*: Name of the animation to play[br]
## * *reverse*: Plays the animation in reverse when true
##
## @ESC
extends ESCBaseCommand
class_name AnimCommand


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
	var obj = escoria.object_manager.get_object(command_params[0])
	var anim_id = command_params[1]
	var reverse = command_params[2]
	var animator: ESCAnimationPlayer = \
			(obj.node as ESCItem).get_animation_player()
	if reverse:
		animator.play_backwards(anim_id)
	else:
		animator.play(anim_id)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
