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
	yield(escoria.get_tree().create_timer(float(command_params[0])), "timeout")
	return ESCExecution.RC_OK
