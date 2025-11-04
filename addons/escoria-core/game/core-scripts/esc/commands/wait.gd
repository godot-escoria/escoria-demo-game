## `wait(seconds: Number)`
##
## Blocks execution of the current event.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |seconds|`Number`|Number of seconds to block|yes|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name WaitCommand

## Timer to wait for
var timer: Timer


## The descriptor of the arguments of this command.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the descriptor of the arguments of this command. The argument descriptor for this command. (`ESCCommandArgumentDescriptor`)
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
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|The arguments to validate.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the arguments are valid, false otherwise. (`bool`)
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
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|The parameters for the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the execution result code. (`int`)
func run(command_params: Array) -> int:
	timer = Timer.new()
	timer.wait_time = float(command_params[0])
	escoria.add_child(timer)
	timer.start()
	await timer.timeout
	escoria.remove_child(timer)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	if timer == null:
		return

	timer.timeout.emit()
