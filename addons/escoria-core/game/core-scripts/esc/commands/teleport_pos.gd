## `teleport_pos(object: String, x: Integer, y: Integer)`
##
## Instantly moves an object to the specified (absolute) coordinates.[br]
##[br]
## **Parameters**[br]
##[br]
## - *object*: Global ID of the object to move[br]
## - *x*: X-coordinate of destination position[br]
## - *y*: Y-coordinate of destination position
##
## @ESC
extends ESCBaseCommand
class_name TeleportPosCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3,
		[TYPE_STRING, TYPE_INT, TYPE_INT],
		[null, null, null]
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
			"Invalid first object. Object to teleport with global id '%s' not found." % arguments[0]
		)
		return false

	if not (escoria.object_manager.get_object(arguments[0]).node as ESCItem):
		raise_error(
			self,
			"Invalid first object.  Object to teleport with global id '%s' must be of or derived from type ESCItem." % arguments[0]
		)
		return false

	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCItem) \
		.teleport_to(
			Vector2(int(command_params[1]), int(command_params[2])
		)
	)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
