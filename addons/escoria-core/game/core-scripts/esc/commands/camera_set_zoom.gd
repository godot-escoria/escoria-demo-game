# `camera_set_zoom magnitude [time]`
#
# Zooms the camera in/out to the desired `magnitude`. Values larger than 1 zooms 
# the camera out, and smaller values zooms in, relative to the default value 
# of 1.
#
# **Parameters**
#
# - *magnitude*: Magnitude to zoom
# - *time*: Number of seconds the transition should take (0)
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCBaseCommand
class_name CameraSetZoomCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[[TYPE_REAL, TYPE_INT], [TYPE_REAL, TYPE_INT]],
		[null, 0.0]
	)


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object("_camera").node as ESCCamera)\
		.set_camera_zoom(
			command_params[0],
			command_params[1]
		)
	return ESCExecution.RC_OK
