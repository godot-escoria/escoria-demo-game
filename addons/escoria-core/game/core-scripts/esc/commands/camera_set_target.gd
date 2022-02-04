# `camera_set_target speed object`
#
# Configures the camera to follow the specified target `object`
#
# **Parameters**
#
# - *speed*: Number of seconds the transition should take
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
	

# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[1]):
		escoria.logger.report_errors(
			"camera_set_target: invalid object",
			[
				"Object with global id %s not found" % arguments[1]
			]
		)
		return false
	
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.set_target(
			escoria.object_manager.get_object(command_params[1]).node,
			command_params[0]
		)
	return ESCExecution.RC_OK
