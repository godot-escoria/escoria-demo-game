## `wait seconds`[br]
## [br]
## Blocks execution of the current event.[br]
## [br]
## #### Parameters[br]
## [br]
## - *seconds*: Number of seconds to block[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name WaitCommand

## Timer to wait for
var timer: Timer


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[[TYPE_INT, TYPE_FLOAT]],
		[null]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	# We can't wait for 0 or fewer seconds, now, can we?
	if arguments[0] <= 0.0:
		raise_error(
			self,
			"Argument invalid. %s is an invalid amount of time to wait (must be positive)." % arguments[0]
		)
		return false

	return true

## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	timer = Timer.new()
	timer.wait_time = float(command_params[0])
	escoria.add_child(timer)
	timer.start()
	await timer.timeout
	escoria.remove_child(timer)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	if timer == null:
		return

	timer.timeout.emit()
