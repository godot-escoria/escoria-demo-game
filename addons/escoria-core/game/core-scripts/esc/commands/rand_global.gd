# `rand_global name max_value`
#
# Sets the given global to a random integer between 0 and `max_value`
# (inclusive). e.g. Setting `max_value` to 2 could result in '0', '1' or '2'
# being returned.
#
# **Parameters**
#
# - *name*: Name of the global to set
# - *max_value*: Maximum possible integer value (inclusive) (default: 1)
#
# @ESC
extends ESCBaseCommand
class_name RandGlobalCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING, TYPE_INT],
		[null, 1]
	)


# Run the command
func run(command_params: Array) -> int:
	randomize()
	var rnd = randi() % (command_params[1] + 1)
	escoria.globals_manager.set_global(
		command_params[0],
		rnd
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
