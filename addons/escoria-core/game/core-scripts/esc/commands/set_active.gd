## `set_active(object: String, active: Boolean)`
##
## Changes the "active" state of the object. Inactive objects are invisible in the room.[br]
##[br]
## **Parameters**[br]
##[br]
## - *object* Global ID of the object[br]
## - *active* Whether `object` should be active. `active` can be `true` or `false`.
##
## @ESC
extends ESCBaseCommand
class_name SetActiveCommand


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_BOOL],
		[null, null]
	)


## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
		return false
	return true


## Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[0]).active = \
			command_params[1]
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
