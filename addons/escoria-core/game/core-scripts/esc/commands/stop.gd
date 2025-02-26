# `stop`
#
# Stops the current event's execution. Note that this will stop the current
# script entirely - if you're within a conditional block, the code after the
# conditional block will not be executed.
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


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
