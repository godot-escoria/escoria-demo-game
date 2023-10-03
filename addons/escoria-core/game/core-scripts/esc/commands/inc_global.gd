# `inc_global name value`
#
# Adds the given value to the specified global.
#
# **Parameters**
#
# - *name*: Name of the global to be changed
# - *value*: Value to be added (default: 1)
#
# @ESC
extends ESCBaseCommand
class_name IncGlobalCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING, TYPE_INT],
		[null, 1]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.globals_manager.has(arguments[0]):
		raise_error(self, "Invalid global. Global %s does not exist." % arguments[0])
		return false
	if not escoria.globals_manager.get_global(arguments[0]) is int:
		raise_error(self, "Invalid global. Global %s isn't an integer value." % arguments[0])
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.globals_manager.set_global(
		command_params[0],
		escoria.globals_manager.get_global(command_params[0]) +\
				command_params[1]
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
