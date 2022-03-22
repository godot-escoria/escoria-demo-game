# `camera_push target [time] [type]`
#
# Pushes (moves) the camera so it points at a specific `target`. If the camera
# was following a target (like the player) previously, it will no longer follow
# this target.
#
# Make sure the target is reachable if camera limits have been configured.
#
# **Parameters**
#
# - *target*: Global ID of the `ESCItem` to push the camera to. `ESCItem`s have
#   a "camera_node" property that can be set to point to a node (usually an
#   `ESCLocation` node). If the "camera_node" property is empty, `camera_push`
#   will point the camera at the `ESCItem`s location. If however, the `ESCItem`
#   has its "camera_node" property set, the command will instead point the
#   camera at the node referenced by the `ESCItem`s "camera_node" property.
# - *time*: Number of seconds the transition should take (default: `1`)
# - *type*: Transition type to use (default: `QUAD`)
#
# Supported transitions include the names of the values used
# in the "TransitionType" enum of the "Tween" type (without the "TRANS_" prefix):
#
# See https://docs.godotengine.org/en/stable/classes/class_tween.html?highlight=tween#enumerations
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCBaseCommand
class_name CameraPushCommand

# The list of supported transitions as per the link mentioned above
const SUPPORTED_TRANSITIONS = ["LINEAR","SINE","QUINT","QUART","QUAD" ,"EXPO","ELASTIC","CUBIC",
	"CIRC","BOUNCE","BACK"]


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING, [TYPE_REAL, TYPE_INT], TYPE_STRING],
		[null, 1, "QUAD"]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"camera_push: invalid object",
			[
				"Object global id %s not found" % arguments[0]
			]
		)
		return false
	if not arguments[2] in SUPPORTED_TRANSITIONS:
		escoria.logger.report_errors(
			"camera_shift: invalid transition type",
			[
				"Transition type {t_type} is not one of the accepted types : {allowed_types}".format(
					{"t_type":arguments[2],"allowed_types":SUPPORTED_TRANSITIONS})
			]
		)
		return false

	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.push(
			escoria.object_manager.get_object(command_params[0]).node,
			command_params[1],
			Tween.new().get("TRANS_%s" % command_params[2])
		)
	return ESCExecution.RC_OK
