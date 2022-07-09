# `camera_set_target time object`
#
# Configures the camera to follow the specified target `object` as it moves
# around the current room. The transition to focus on the `object` will happen
# over a time period.
#
# **Parameters**
#
# - *time*: Number of seconds the transition should take to move the camera
#   to follow `object`
# - *object*: Global ID of the target object
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCBaseCommand
class_name CameraSetTargetCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[[TYPE_REAL, TYPE_INT], TYPE_STRING],
		[null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[1]):
		escoria.logger.error(
			self,
			"[%s]: Invalid object: Object with global id %s not found." 
					% [get_command_name(), arguments[1]]
		)
		return false

	return true


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.set_target(
			escoria.object_manager.get_object(command_params[1]).node,
			command_params[0]
		)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.warn(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
