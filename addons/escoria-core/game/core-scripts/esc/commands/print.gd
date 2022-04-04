# `print string`
#
# Prints a message to the log. Use this for debugging game state.
#
# **Parameters**
#
# - *string*: The string to log
#
# @ESC
extends ESCBaseCommand
class_name PrintCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING],
		[""]
	)


# Run the command
func run(command_params: Array) -> int:
	print(command_params[0])
	return ESCExecution.RC_OK
