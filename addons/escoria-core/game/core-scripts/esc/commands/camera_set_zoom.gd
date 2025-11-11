## `camera_set_zoom(magnitude: Number[, time: Number])`
##
## Zooms the camera in/out to the desired `magnitude`. Values larger than '1' zoom
## the camera out while smaller values zoom in. These values are relative to the
## default zoom value of '1', not the current value. As such, while using a value
## of '0.5' would double the size of the graphics, running the same command again
## would result in no change. The zoom will happen over the given time period.[br]
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
class_name CameraSetZoomCommand


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
			command_params[0],
			command_params[1]
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
