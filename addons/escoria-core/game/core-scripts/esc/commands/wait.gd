# `wait seconds`
#
# Blocks execution of the current event.
#
# **Parameters**
#
# - *seconds*: Number of seconds to block
#
# @ESC
extends ESCBaseCommand
class_name WaitCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[[TYPE_INT, TYPE_REAL]],
		[null]
	)


# Run the command
func run(command_params: Array) -> int:
	yield(escoria.get_tree().create_timer(float(command_params[0])), "timeout")
	return ESCExecution.RC_OK
