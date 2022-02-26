# `set_global name value`
#
# Changes the value of a global.
#
# **Parameters**
#
# - *name*: Name of the global
# - *value*: Value to set the global to (can be of type string, boolean, integer
#   or float)
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
