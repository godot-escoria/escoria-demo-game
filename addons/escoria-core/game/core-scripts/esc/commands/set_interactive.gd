## `set_interactive object interactive`
##
## Sets whether an object is interactive.[br]
##[br]
## **Parameters**[br]
##[br]
## - *object*: Global ID of the object to change[br]
## - *interactive*: Whether the object should be interactive
##
## @ESC
extends ESCBaseCommand
class_name SetInteractiveCommand


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
	escoria.object_manager.get_object(command_params[0]).interactive = \
			command_params[1]
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
