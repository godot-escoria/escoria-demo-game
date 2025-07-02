## `turn_to(object: String, object_to_face: String[, wait: Number])`
##
## Turns `object` to face another object.[br]
##[br]
## Unlike movement commands, `turn_to` will not automatically reference an
## `ESCLocation` that is a child of an `ESCItem.`
## To turn towards an `ESCLocation` that is a child of an `ESCItem`, give the
## `ESCLocation` a `Global ID` and use this value as the `object_to_face`
## parameter.[br]
##[br]
## While turning, the number of directions the item faces will depend on
## the number of `directions` defined for the object. A 16 direction character
## for example will display 8 directions of animation while turning to face an
## object that is 180 degrees away, a 4 direction character would only face 2
## directions to make the same turn. As the idle animation will be played for
## `wait` seconds for each direction the object faces, a 16 direction character
## would take 8 seconds to rotate 180 degrees with a 1 second `wait` time,
## whereas a 4 direction character would only take 2 seconds to make the same
## rotation.[br]
##[br]
## **Parameters**[br]
##[br]
## - *object*: Global ID of the object to be turned[br]
## - *object_to_face*: Global ID of the object to turn towards[br]
## - *wait*: Length of time to wait in seconds for each intermediate angle.
##   If set to 0, the turnaround is immediate (default: `0`)
##
## @ESC
extends ESCBaseCommand
class_name TurnToCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_FLOAT],
		[null, null, 0.0]
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
		raise_invalid_object_error(self, arguments[0])
		return false
	if not escoria.object_manager.has(arguments[1]):
		raise_error(
			self,
			"Cannot turn \"%s\" towards \"%s\". \"%s\" was not found."
				% [arguments[0], arguments[1] , arguments[1]]
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
	(escoria.object_manager.get_object(command_params[0]).node as ESCItem)\
		.turn_to(
			escoria.object_manager.get_object(command_params[1]).node,
			command_params[2]
		)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
