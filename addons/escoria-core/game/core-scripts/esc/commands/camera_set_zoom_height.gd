# `camera_set_zoom_height pixels [time]`
#
# Zooms the camera in/out to the desired `pixels` height. 
# An optional `time` in seconds controls how long it takes for the camera 
# to zoom into position.
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
	(escoria.object_manager.get_object("_camera").node as ESCCamera)\
		.set_camera_zoom(
			command_params[0] / escoria.game_size.y,
			command_params[1]
		)
	return ESCExecution.RC_OK
