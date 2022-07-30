# `camera_shift x y [time] [type]`
#
# Shifts the camera by the given horizontal and vertical amounts relative to the
# current location.
#
# **Parameters**
#
# - *x*: Shift by x pixels along the x-axis
# - *y*: Shift by y pixels along the y-axis
# - *time*: Number of seconds the transition should take, with a value of `0`
#   meaning the zoom should happen instantly (default: `1`)
# - *type*: Transition type to use (default: `QUAD`)
#
# Supported transitions include the names of the values used
# in the "TransitionType" enum of the "Tween" type (without the "TRANS_" prefix):
#
# https://docs.godotengine.org/en/stable/classes/class_tween.html?highlight=tween#enumerations
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCBaseCommand
class_name CameraShiftCommand

# The list of supported transitions as per the link mentioned above
const SUPPORTED_TRANSITIONS = ["LINEAR","SINE","QUINT","QUART","QUAD" ,"EXPO","ELASTIC","CUBIC",
	"CIRC","BOUNCE","BACK"]

# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[
			[TYPE_INT, TYPE_REAL],
			[TYPE_INT, TYPE_REAL],
			[TYPE_INT, TYPE_REAL],
			TYPE_STRING
		],
		[null, null, 1, "QUAD"]
	)


# Run the command
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


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not arguments[3] in SUPPORTED_TRANSITIONS:
		escoria.logger.error(
			self,
			(
				"[{command_name}]: invalid transition type" +
				"Transition type {t_type} is not one of the accepted types : {allowed_types}"
			).format(
				{
					"command_name": get_command_name(),
					"t_type":arguments[3],
					"allowed_types":SUPPORTED_TRANSITIONS
				}
			)
		)
		return false

	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera
	# has_point() is exclusive of right-/bottom-edge
	var camera_limit_to_test: Rect2 = Rect2(camera.limit_left, camera.limit_top, camera.limit_right - camera.limit_left + 1, camera.limit_bottom - camera.limit_top + 1)
	var camera_limit: Rect2 = Rect2(camera.limit_left, camera.limit_top, camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top)
	var shift_by: Vector2 = Vector2(arguments[0], arguments[1])
	var new_pos: Vector2 = Vector2(camera.position.x + shift_by.x, camera.position.y + shift_by.y)

	if not camera_limit_to_test.has_point(new_pos):
		escoria.logger.warn(
			self,
			"[%s]: invalid camera position. Camera cannot be moved by %s to %s as this is outside the current camera limit %s."
				% [
					get_command_name(),
					shift_by,
					new_pos,
					camera_limit
				]
		)
		return false

	return true


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.warn(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
