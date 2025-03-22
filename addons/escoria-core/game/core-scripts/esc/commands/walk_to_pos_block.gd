## `walk_to_pos_block object x y [walk_fast]`[br]
## [br]
## Moves the specified `ESCPlayer` or movable `ESCItem` to the absolute
## coordinates provided while playing the `object`'s walking animation.[br]
## This command is blocking.[br]
## This command will use the normal walk speed by default.[br]
## [br]
## #### Parameters[br]
## [br]
## - *object*: Global ID of the object to move[br]
## - *x*: X-coordinate of target position[br]
## - *y*: Y-coordinate of target position[br]
## - *walk_fast*: Whether to walk fast (`true`) or normal speed (`false`).
##   (default: false)[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name WalkToPosBlockCommand


## Walking object
var walking_object_node: ESCItem


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3,
		[TYPE_STRING, TYPE_INT, TYPE_INT, TYPE_BOOL],
		[null, null, null, false]
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

	if not escoria.object_manager.has(arguments[0]):
		raise_error(
			self,
			"Invalid first object. The object to make walk with global id '%s' was not found." % arguments[0]
		)
		return false

	walking_object_node = (escoria.object_manager.get_object(
		arguments[0]).node as ESCItem
	)
	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	escoria.action_manager.do(escoria.action_manager.ACTION.BACKGROUND_CLICK, [
		command_params[0],
		Vector2(command_params[1], command_params[2]), command_params[3]
	])
	await (escoria.object_manager.get_object(command_params[0]).node as ESCItem).arrived
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	if walking_object_node != null and not walking_object_node is ESCPlayer:
		walking_object_node.stop_walking_now()
