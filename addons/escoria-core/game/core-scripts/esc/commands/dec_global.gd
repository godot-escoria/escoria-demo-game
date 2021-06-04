# `dec_global name value`
# 
# Subtracts the value from global with given "name". Value and global must 
# both be integers.
# 
# @ESC
extends ESCBaseCommand
class_name DecGlobalCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_INT],
		[null, 0]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.globals_manager.get(arguments[0]) is int:
		escoria.logger.report_errors(
			"dec_global: invalid global",
			[
				"Global %s didn't have an integer value." % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.globals_manager.set_global(
		command_params[0],
		escoria.globals_manager.get_global(command_params[0]) - \
				command_params[1]
	)
	return ESCExecution.RC_OK
