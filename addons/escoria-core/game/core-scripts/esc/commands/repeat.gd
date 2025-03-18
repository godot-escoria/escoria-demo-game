## `repeat()`
##
## Makes the current script loop back to the start. Currently the only way to
## exit the loop is via the `stop` command which will stop the script
## completely.
##
## @ESC
extends ESCBaseCommand
class_name RepeatCommand


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0,
		[],
		[]
	)


## Run the command
func run(command_params: Array) -> int:
	return ESCExecution.RC_CANCEL


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
