# `set_interactive object interactive`
#
# Sets whether an object should be interactive.
#
# **Parameters**
#
# - *object*: Global ID of the object to change
# - *interactive*: Whether the object should be interactive
#
# @ESC
extends ESCBaseCommand
class_name SetInteractiveCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_BOOL],
		[null, null]
	)
	

# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"set_interactive: invalid object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[0]).interactive = \
			command_params[1]
	return ESCExecution.RC_OK
