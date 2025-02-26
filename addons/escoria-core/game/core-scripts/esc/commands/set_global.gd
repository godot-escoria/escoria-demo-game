# `set_global name value [force=false]`
#
# Changes the value of a global.
#
# **Parameters**
#
# - *name*: Name of the global
# - *value*: Value to set the global to (can be of type string, boolean, integer
#   or float)
# - *force*: if false, setting a global whose name is reserved will
#   trigger an error. Defaults to false. Reserved globals are: ESC_LAST_SCENE,
#   FORCE_LAST_SCENE_NULL, ANIMATION_RESOURCES, ESC_CURRENT_SCENE
#
# @ESC
extends ESCBaseCommand
class_name SetGlobalCommand


const ILLEGAL_STRINGS = ["/"]


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, [TYPE_INT, TYPE_BOOL, TYPE_STRING], TYPE_BOOL],
		[null, null, false]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	for s in ILLEGAL_STRINGS:
		if s in arguments[0]:
			raise_error(
				self,
				"Invalid global variable. Global variable '%'s cannot contain the string '%s'."
					% [arguments[0], s]
			)
			return false

	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.globals_manager.set_global(
		command_params[0],
		command_params[1],
		command_params[2]
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
