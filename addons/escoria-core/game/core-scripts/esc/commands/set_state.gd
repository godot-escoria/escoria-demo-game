# `set_state object state [immediate]`
#
# Changes the state of `object` to the one specified.
#
# If the specified object's associated animation player has an animation
# with the same name, that that animation is also played.
#
# Can be used to change the appearance of an item or player
# character. See https://docs.escoria-framework.org/states for details.
#
# **Parameters**
#
# - *object*: Global ID of the object whose state is to be changed
# - *immediate*: If an animation for the state exists, specifies
#   whether it is to skip to the last frame. Can be `true` or `false`.
#
# @ESC
extends ESCBaseCommand
class_name SetStateCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_BOOL],
		[null, null, false]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"set_state: invalid object",
			[
				"Object %s not found." % arguments[0]
			]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]) as ESCObject).set_state(
		command_params[1],
		command_params[2]
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
