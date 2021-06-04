# `stop`
#
# Stops the event's execution.
# 
# @ESC
extends ESCBaseCommand
class_name StopCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0, 
		[],
		[]
	)


# Run the command
func run(command_params: Array) -> int:
	return ESCExecution.RC_CANCEL
