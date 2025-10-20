## `camera_shift(x: Number, y: Number[, time: Number[, type: String]])`
##
## Shifts the camera by the given horizontal and vertical amounts relative to the
## current location.[br]
##[br]
## **Parameters**[br]
##[br]
## - *x*: Shift by x pixels along the x-axis[br]
## - *y*: Shift by y pixels along the y-axis[br]
## - *time*: Number of seconds the transition should take, with a value of `0`
##   meaning the zoom should happen instantly (default: `1`)[br]
## - *type*: Transition type to use (default: `QUAD`)[br]
##[br]
## Supported transitions include the names of the values used
## in the "TransitionType" enum of the "Tween" type (without the "TRANS_" prefix):[br]
##[br]
## https://docs.godotengine.org/en/stable/classes/class_tween.html?highlight=tween#enumerations[br]
##[br]
## For more details see: https://docs.escoria-framework.org/camera
##
## @ESC
extends ESCCameraBaseCommand
class_name CameraShiftCommand

## The list of supported transitions as per the link mentioned above
const SUPPORTED_TRANSITIONS = ["LINEAR","SINE","QUINT","QUART","QUAD" ,"EXPO","ELASTIC","CUBIC",
	"CIRC","BOUNCE","BACK"]

## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[
			[TYPE_INT, TYPE_FLOAT],
			[TYPE_INT, TYPE_FLOAT],
			[TYPE_INT, TYPE_FLOAT],
			TYPE_STRING
		],
		[null, null, 1, "QUAD"]
	)


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.shift(
			Vector2(
				command_params[0],
				command_params[1]
			),
			command_params[2],
			ClassDB.class_get_integer_constant("Tween", "TRANS_%s" % command_params[3])
		)
	return ESCExecution.RC_OK


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

	if not arguments[3] in SUPPORTED_TRANSITIONS:
		raise_error(self, ("Invalid transition type. " +
				"Transition type {t_type} is not one of the accepted types: {allowed_types}").format(
				{
					"t_type": arguments[3],
					"allowed_types": SUPPORTED_TRANSITIONS
				}
			)
		)

		return false

	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera
	var shift_by: Vector2 = Vector2(arguments[0], arguments[1])
	var new_pos: Vector2 = Vector2(camera.position.x + shift_by.x, camera.position.y + shift_by.y)

	if not camera.check_point_is_inside_viewport_limits(new_pos):
		generate_viewport_warning(new_pos, camera)
		return false

	return true


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
