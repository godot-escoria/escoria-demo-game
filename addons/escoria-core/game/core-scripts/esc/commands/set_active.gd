# `set_active object active`
#
# Changes the "active" state of the object.
# Inactive objects are invisible in the room.
#
# **Parameters**
#
# - *object* Global ID of the object
# - *active* Whether `object` should be active. `active` can be `true` or `false`.
#
# @ESC
extends ESCBaseCommand
class_name SetActiveCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_BOOL],
		[null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"set_active: invalid object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[0]).active = \
			command_params[1]
	return ESCExecution.RC_OK
