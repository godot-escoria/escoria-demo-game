## `camera_set_zoom_height_block(pixels: Integer[, time: Number])`
##
## Zooms the camera in/out so it occupies the given height in pixels. Blocks until the command completes.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |pixels|`Integer`|Target height in pixels (integer values only)|yes|[br]
## |time|`Number`|Number of seconds the transition should take, with a value of `0` meaning the zoom should happen instantly (default: `0`) For more details see: https://docs.escoria-framework.org/camera|no|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name CameraSetZoomHeightBlockCommand


## Tween for blocking
var _camera_tween: Tween3


## The descriptor of the arguments of this command.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the descriptor of the arguments of this command. The argument descriptor for this command. (`ESCCommandArgumentDescriptor`)
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
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|The arguments to validate.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the arguments are valid, false otherwise. (`bool`)
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
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|The parameters for the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the execution result code. (`int`)
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


## Function called when the command is interrupted.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
