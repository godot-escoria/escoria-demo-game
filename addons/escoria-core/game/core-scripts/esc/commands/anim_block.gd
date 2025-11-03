## `anim_block(object: String, name: String[, reverse: Boolean])`
##
## Executes the animation specified in "name" on "object" while blocking other events from starting. The next command in the event will be executed when the animation is finished playing.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Global ID of the object with the animation|yes|[br]
## |name|`String`|Name of the animation to play before continuing.|yes|[br]
## |reverse|`Boolean`|Plays the animation in reverse when true|no|[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name AnimBlockCommand


## The descriptor of the arguments of this command.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the descriptor of the arguments of this command. The argument descriptor for this command. (`ESCCommandArgumentDescriptor`)
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
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|The arguments to validate.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the arguments are valid, false otherwise. (`bool`)
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
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|The parameters for the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the execution result code. (`int`)
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
	if animator.get_length(anim_id) < 1.0:
		return ESCExecution.RC_OK
	var animation_finished = await animator.animation_finished
	while animation_finished != anim_id:
		animation_finished = await animator.animation_finished
	return ESCExecution.RC_OK


## Function called when the command is interrupted.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
