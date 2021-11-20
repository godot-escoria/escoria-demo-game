# `debug string [string2 ...]`
#
# Prints a DEBUG-level message to the log.
#
# **Parameters**
#
# - *string*: One or more strings to log
#
# @ESC
extends ESCBaseCommand
class_name DebugCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_STRING],
		[""]
	)
	

# Run the command
func run(command_params: Array) -> int:
	escoria.logger.debug("debug command issued", command_params)
	return ESCExecution.RC_OK
