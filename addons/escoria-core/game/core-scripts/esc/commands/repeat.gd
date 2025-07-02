## `repeat()`
##
## Makes the current script loop back to the start. Currently the only way to
## exit the loop is via the `stop` command which will stop the script
## completely.
##
## @ESC
extends ESCBaseCommand
class_name RepeatCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0,
		[],
		[]
	)


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	return ESCExecution.RC_CANCEL


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
