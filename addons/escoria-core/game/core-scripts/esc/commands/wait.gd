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

# Timer to wait for
var timer: Timer


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[[TYPE_INT, TYPE_REAL]],
		[null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	# We can't wait for 0 or fewer seconds, now, can we?
	if arguments[0] <= 0.0:
		escoria.logger.report_errors(
			"wait: argument invalid",
			[
				"%ss is an invalid amount of time to wait." % arguments[0],
				"Time to wait must be positive."
			]
		)
		return false

	return true

# Run the command
func run(command_params: Array) -> int:
	timer = Timer.new()
	timer.wait_time = float(command_params[0])
	escoria.add_child(timer)
	timer.start()
	yield(timer, "timeout")
	escoria.remove_child(timer)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	timer.emit_signal("timeout")
