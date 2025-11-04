## `walk_to_pos_block(object: String, x: Integer, y: Integer[, walk_fast: Boolean])`
##
## Moves the specified `ESCPlayer` or movable `ESCItem` to the absolute coordinates provided while playing the `object`'s walking animation. This command is blocking. This command will use the normal walk speed by default.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Global ID of the object to move|yes|[br]
## |x|`Integer`|X-coordinate of target position|yes|[br]
## |y|`Integer`|Y-coordinate of target position|yes|[br]
## |walk_fast|`Boolean`|Whether to walk fast (`true`) or normal speed (`false`). (default: false)|no|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name WalkToPosBlockCommand


## Walking object
var walking_object_node: ESCItem


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
		3,
		[TYPE_STRING, TYPE_INT, TYPE_INT, TYPE_BOOL],
		[null, null, null, false]
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
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|The parameters for the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the execution result code. (`int`)
func run(command_params: Array) -> int:
	escoria.action_manager.do(escoria.action_manager.ACTION.BACKGROUND_CLICK, [
		command_params[0],
		Vector2(command_params[1], command_params[2]), command_params[3]
	])
	await (escoria.object_manager.get_object(command_params[0]).node as ESCItem).arrived
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
	if walking_object_node != null and not walking_object_node is ESCPlayer:
		walking_object_node.stop_walking_now()
