# `camera_set_zoom_block magnitude [time]`
#
# Zooms the camera in/out to the desired `magnitude`. Values larger than '1' zoom
# the camera out while smaller values zoom in. These values are relative to the
# default zoom value of '1', not the current value. As such, while using a value
# of '0.5' would double the size of the graphics, running the same command again
# would result in no change. The zoom will happen over the given time period.
# Blocks until the command completes.
#
# Zoom operations might not be as smooth as desired if the requested zoom
# level results in an edge of the camera meeting any defined camera limits.
#
# **Parameters**
#
# - *magnitude*: Magnitude of zoom
# - *time*: Number of seconds the transition should take, with a value of `0`
#   meaning the zoom should happen instantly (default: `0`)
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCCameraBaseCommand
class_name CameraSetZoomBlockCommand


var _camera_tween: Tween


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[[TYPE_REAL, TYPE_INT], [TYPE_REAL, TYPE_INT]],
		[null, 0.0]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera
	_camera_tween = camera.get_tween()

	return true


# Run the command
func run(command_params: Array) -> int:
	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera

	camera\
		.set_camera_zoom(
			command_params[0],
			command_params[1]
		)

	if command_params[1] > 0.0:
		yield(_camera_tween, "tween_completed")
	escoria.logger.debug(
			self,
			"camera_set_zoom_block tween complete."
		)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
