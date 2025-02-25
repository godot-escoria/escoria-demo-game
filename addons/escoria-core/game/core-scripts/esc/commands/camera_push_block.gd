## `camera_push_block target [time] [type]`
##
## Pushes (moves) the camera so it points at a specific `target`. If the camera
## was following a target (like the player) previously, it will no longer follow
## this target. Blocks until the command completes.[br]
##[br]
## Make sure the target is reachable if camera limits have been configured.[br]
##[br]
## **Parameters**[br]
##[br]
## - *target*: Global ID of the `ESCItem` to push the camera to. `ESCItem`s have
##   a "camera_node" property that can be set to point to a node (usually an
##   `ESCLocation` node). If the "camera_node" property is empty, `camera_push_block`
##   will point the camera at the `ESCItem`s location. If however, the `ESCItem`
##   has its "camera_node" property set, the command will instead point the
##   camera at the node referenced by the `ESCItem`s "camera_node" property.[br]
## - *time*: Number of seconds the transition should take (default: `1`)[br]
## - *type*: Transition type to use (default: `QUAD`)[br]
##[br]
## Supported transitions include the names of the values used
## in the "TransitionType" enum of the "Tween" type (without the "TRANS_" prefix).[br]
##[br]
## See https://docs.godotengine.org/en/stable/classes/class_tween.html?highlight=tween#enumerations[br]
##[br]
## For more details see: https://docs.escoria-framework.org/camera
##
## @ESC
extends ESCCameraBaseCommand
class_name CameraPushBlockCommand


## The list of supported transitions as per the link mentioned above
const SUPPORTED_TRANSITIONS = ["LINEAR","SINE","QUINT","QUART","QUAD" ,"EXPO","ELASTIC","CUBIC",
	"CIRC","BOUNCE","BACK"]


## Tween for blocking
var _camera_tween: Tween3


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING, [TYPE_FLOAT, TYPE_INT], TYPE_STRING],
		[null, 1, "QUAD"]
	)


## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
		return false

	var target_pos = _get_target_pos(arguments[0])
	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera

	if not camera.check_point_is_inside_viewport_limits(target_pos):
		generate_viewport_warning(target_pos, camera)
		return false

	if not arguments[2] in SUPPORTED_TRANSITIONS:
		raise_error(self, ("Invalid transition type. Transition type {t_type} " +
				"is not one of the accepted types: {allowed_types}").format(
					{
						"t_type": arguments[2],
						"allowed_types": SUPPORTED_TRANSITIONS
					}
				))

		return false

	_camera_tween = camera.get_tween()

	return true


## Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.push(
			escoria.object_manager.get_object(command_params[0]).node,
			command_params[1],
			ClassDB.class_get_integer_constant("Tween", "TRANS_%s" % command_params[2])
		)

	if command_params[1] > 0.0:
		await _camera_tween.finished
		escoria.logger.debug(
			self,
			"camera_push_block tween complete."
		)

	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)


## Gets the appropriate target position from the `ESCItem`, as used by the camera.
##
## ######## Parameters
##
## - target_global_id: The `global_id` of the `ESCItem` to check.
##
## **Returns** the ESCitem's position based on its camera node.
func _get_target_pos(target_global_id: String) -> Vector2:
	var target = escoria.object_manager.get_object(target_global_id).node as ESCItem
	return target.get_camera_node().global_position
