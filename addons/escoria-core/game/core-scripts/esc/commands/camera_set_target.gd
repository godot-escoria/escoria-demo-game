## `camera_set_target(time: Number, object: String)`
##
## Configures the camera to follow the supplied Escoria object, easing into the new target over the requested duration.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |time|`Number`|Duration in seconds for the camera to transition to the target.|yes|[br]
## |object|`String`|Global ID of the object the camera should follow.|yes|[br]
## [br]
## For more details see: https://docs.escoria-framework.org/camera[br]
##
## @ESC
extends ESCCameraBaseCommand
class_name CameraSetTargetCommand


## Provides the argument descriptor that defines the command signature.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the descriptor used to validate command arguments. (`ESCCommandArgumentDescriptor`)
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[[TYPE_FLOAT, TYPE_INT], TYPE_STRING],
		[null, null]
	)


## Validates the command arguments and ensures the target object exists.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|Command arguments to check against the descriptor.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns `true` when the arguments are valid; otherwise `false`. (`bool`)
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[1]):
		raise_invalid_object_error(self, arguments[1])
		return false

	return true


## Applies the camera target using the provided arguments.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|Execution parameters `[time, object_id]` for the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the command execution result code. (`int`)
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.set_target(
			escoria.object_manager.get_object(command_params[1]).node,
			command_params[0]
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
