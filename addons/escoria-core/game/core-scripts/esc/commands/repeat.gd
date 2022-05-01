# `repeat`
#
# Restarts the execution of the current scope at the start. A scope can be a
# group or an event.
#
# @ESC
extends ESCBaseCommand
class_name RepeatCommand


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
