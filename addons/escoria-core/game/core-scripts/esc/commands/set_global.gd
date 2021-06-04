# `set_global name value`
#
# Changes the value of the global "name" with the value. Value can be "true", 
# "false" or an integer.
#
# @ESC
extends ESCBaseCommand
class_name SetGlobalCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, [TYPE_INT, TYPE_BOOL, TYPE_STRING]],
		[null, null]
	)


# Run the command
func run(command_params: Array) -> int:
	escoria.globals_manager.set_global(command_params[0], command_params[1])
	return ESCExecution.RC_OK
