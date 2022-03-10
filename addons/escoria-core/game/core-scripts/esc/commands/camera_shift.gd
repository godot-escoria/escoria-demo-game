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
			Tween.new().get("TRANS_%s" % command_params[3])
		)
	return ESCExecution.RC_OK

# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not arguments[3] in SUPPORTED_TRANSITIONS:
		escoria.logger.report_errors(
			"camera_shift: invalid transition type",
			[
				"Transition type {t_type} is not one of the accepted types : {allowed_types}".format(
					{"t_type":arguments[3],"allowed_types":SUPPORTED_TRANSITIONS})
			]
		)
		return false

	return .validate(arguments)
