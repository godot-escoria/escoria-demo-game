## `camera_set_zoom_height_block(pixels: Integer[, time: Number])`
##
## Zooms the camera in/out so it occupies the given height in pixels.
## Blocks until the command completes.[br]
##[br]
## **Parameters**[br]
##[br]
## - *pixels*: Target height in pixels (integer values only)[br]
## - *time*: Number of seconds the transition should take, with a value of `0`
##   meaning the zoom should happen instantly (default: `0`)[br]
##[br]
## For more details see: https://docs.escoria-framework.org/camera
##
## @ESC
extends ESCBaseCommand
class_name CameraSetZoomHeightBlockCommand


## Tween for blocking
var _camera_tween: Tween3


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_INT, [TYPE_INT, TYPE_FLOAT]],
		[null, 0.0]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if arguments[0] <= 0:
		raise_error(self, "Invalid height. Can't zoom to a negative height (%d)." % arguments[0])
		return false

	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera
	_camera_tween = camera.get_tween()

	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.set_camera_zoom(
			command_params[0] / escoria.game_size.y,
			command_params[1]
		)

	if command_params[1] > 0.0:
		await _camera_tween.finished
	escoria.logger.debug(
			self,
			"camera_set_zoom_height_block tween complete."
		)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
