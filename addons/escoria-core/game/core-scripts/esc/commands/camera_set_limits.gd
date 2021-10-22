# `camera_set_limits camlimits_id`
#
# Sets the camera limits to the one defined under `camlimits_id` in ESCRoom's 
# camera_limits array.
# - camlimits_id: int: id of the camera limits to apply (defined in ESCRoom's 
#   camera_limits array)
#
# @ESC
extends ESCBaseCommand
class_name CameraSetLimitsCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_INT],
		[null]
	)
	
	
# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if escoria.main.current_scene.camera_limits.size() < arguments[0]:
		escoria.logger.report_errors(
			"camera_set_limits: invalid limits id",
			[
				"Limit id %d is bigger than limits array size %d" % [
					arguments[0],
					escoria.main.current_scene.camera_limits.size()
				]
			]
		)
		return false
	
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.main.set_camera_limits(command_params[0])
	return ESCExecution.RC_OK
