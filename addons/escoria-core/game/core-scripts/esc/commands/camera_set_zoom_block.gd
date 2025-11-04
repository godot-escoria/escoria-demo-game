## `camera_set_zoom_block(magnitude: Number[, time: Number])`
##
## Zooms the camera in/out to the desired `magnitude`. Values larger than '1' zoom
## the camera out while smaller values zoom in. These values are relative to the
## default zoom value of '1', not the current value. As such, while using a value
## of '0.5' would double the size of the graphics, running the same command again
## would result in no change. The zoom will happen over the given time period.
## Blocks until the command completes.[br]
##[br]
## Zoom operations might not be as smooth as desired if the requested zoom
## level results in an edge of the camera meeting any defined camera limits.[br]
##[br]
## **Parameters**[br]
##[br]
## - *magnitude*: Magnitude of zoom[br]
## - *time*: Number of seconds the transition should take, with a value of `0`
##   meaning the zoom should happen instantly (default: `0`)[br]
##[br]
## For more details see: https://docs.escoria-framework.org/camera
##
## @ESC
## @COMMAND
extends ESCCameraBaseCommand
class_name CameraSetZoomBlockCommand


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
		[[TYPE_FLOAT, TYPE_INT], [TYPE_FLOAT, TYPE_INT]],
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
	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera

	camera.set_camera_zoom(command_params[0], command_params[1])

	if command_params[1] > 0.0:
		await _camera_tween.finished
	escoria.logger.debug(
			self,
			"camera_set_zoom_block tween complete."
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
