# `debug string [string2 ...]`
#
# Prints a message to the Godot debug window.
# Use this for debugging game state.
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
	# Replace the names of any globals in "{ }" with their value
	print(escoria.logger.replace_globals(command_params[0]))
	return ESCExecution.RC_OK
