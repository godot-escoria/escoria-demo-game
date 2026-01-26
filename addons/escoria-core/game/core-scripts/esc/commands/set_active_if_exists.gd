## *** FOR INTERNAL USE ONLY *** `set_active_if_exists(object: String, active: Boolean)`
##
## Changes the "active" state of the object in the current room if it currently exists in the object manager. If it doesn't, then, unlike set_active, we don't fail and we just carry on. Inactive objects are invisible in the room.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Global ID of the object whose active state should change if it is registered.|yes|[br]
## |active|`Boolean`|Whether the object should be marked as active (`true`) or inactive (`false`).|yes|[br]
## [br]
## @ASHES
## @COMMAND
extends ESCBaseCommand
class_name SetActiveIfExistsCommand


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
		[TYPE_STRING, TYPE_BOOL],
		[null, null]
	)


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
	if escoria.object_manager.has(command_params[0]):
		escoria.object_manager.get_object(command_params[0]).active = \
				command_params[1]
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
