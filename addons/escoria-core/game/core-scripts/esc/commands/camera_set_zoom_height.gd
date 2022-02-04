# `camera_set_zoom_height pixels [time]`
#
# Zooms the camera in/out so it occupies the given height in pixels
#
# **Parameters**
#
# - *pixels*: Target height in pixels
# - *time*: Number of seconds the transition should take, with a value of `0`
#   meaning the zoom should happen instantly (default: `0`)
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCBaseCommand
class_name CameraSetZoomHeightCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_INT, [TYPE_INT, TYPE_REAL]],
		[null, 0.0]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if arguments[0] < 0:
		escoria.logger.report_errors(
			"camera_set_zoom_height: invalid height",
			[
				"Can't zoom to a negative height %d" % arguments[0]
			]
		)
		return false
	
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.set_camera_zoom(
			command_params[0] / escoria.game_size.y,
			command_params[1]
		)
	return ESCExecution.RC_OK
