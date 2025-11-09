## `set_state(object: String, state: String[, immediate: Boolean])`
##
## Changes the state of `object` to the one specified. This command is primarily used to play animations. If the specified object's associated animation player has an animation with the same name, that animation is also played. When the "state" of the object is set - for example, a door may be set to a "closed" state - this plays the matching "close" animation if one exists (to show the door closing in the game). When you re-enter the room (via a different entry), or restore a saved game, the state of the door object will be restored - showing the door as a closed door.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Global ID of the object whose state is to be changed|yes|[br]
## |state|`String`|Name of the state to be set|yes|[br]
## |immediate|`Boolean`|If an animation for the state exists, specifies whether it is to skip to the last frame. Can be `true` or `false`.|no|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name SetStateCommand


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
	(escoria.object_manager.get_object(command_params[0]) as ESCObject).set_state(
		command_params[1],
		command_params[2]
	)
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
	# Do nothing
	pass
