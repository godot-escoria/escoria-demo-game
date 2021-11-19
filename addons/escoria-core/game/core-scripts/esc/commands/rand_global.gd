# `rand_global name max_value`
#
# Set the given global to a randomized value.
#
# **Parameters**
#
# - *name*: Name of the global to set
# - *max_value*: Maximum value to set
#
# @ESC
extends ESCBaseCommand
class_name RandGlobalCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_INT],
		[null, 1]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.globals_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"inc_global: invalid global",
			[
				"Global %s does not exist." % arguments[0]
			]
		)
		return false
	if not escoria.globals_manager.get(arguments[0]) is int:
		escoria.logger.report_errors(
			"inc_global: invalid global",
			[
				"Global %s didn't have an integer value." % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	randomize()
	var rnd = randi() % command_params[1]
	escoria.globals_manager.set_global(
		command_params[0], 
		rnd
	)
	return ESCExecution.RC_OK
