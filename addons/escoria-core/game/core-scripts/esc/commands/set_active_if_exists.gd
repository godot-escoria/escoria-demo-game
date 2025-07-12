## *** INTERNAL USE ONLY ***[br]
## [br]
## `set_active_if_exists object active`[br]
## [br]
## Changes the "active" state of the object in the current room if it currently
## exists in the object manager. If it doesn't, then, unlike set_active, we don't
## fail and we just carry on.[br]
## [br]
## Inactive objects are invisible in the room.[br]
## [br]
## #### Parameters[br]
## [br]
## - *object* Global ID of the object[br]
## - *active* Whether `object` should be active. `active` can be `true` or `false`.[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name SetActiveIfExistsCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
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
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	if escoria.object_manager.has(command_params[0]):
		escoria.object_manager.get_object(command_params[0]).active = \
				command_params[1]
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
