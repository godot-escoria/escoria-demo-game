## `accept_input [type]`[br]
## [br]
## Sets how much input the game is to accept. This allows for cut scenes in which
## dialogue can be skipped (if [type] is set to SKIP), and ones where it can't
## (if [type] is set to NONE).[br]
## [br]
## #### Parameters[br]
## [br]
## - *type*: Type of inputs to accept (ALL).[br]
##   `ALL`: Accept all types of user input.[br]
##   `SKIP`: Accept skipping dialogues but nothing else.[br]
##   `NONE`: Deny all inputs (including opening menus).[br]
## [br]
## **Warning**: `SKIP` and `NONE` also disable autosaves.[br]
## [br]
## **Warning**: The type of user input accepted will persist even after the
## current event has ended. Remember to reset the input type at the end of
## cut-scenes![br]
## [br]
## @ESC
extends ESCBaseCommand
class_name AcceptInputCommand


## The list of supported input types.
const SUPPORTED_INPUT_TYPES = ["ALL", "NONE", "SKIP"]

## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING],
		["ALL"]
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

	if not arguments[0] in SUPPORTED_INPUT_TYPES:
		raise_error(self, "Invalid parameter. %s is not a valid value. " +
			"Should be one of: %s"
					% [
						arguments[0],
						str(SUPPORTED_INPUT_TYPES)
					])
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
	var mode = escoria.inputs_manager.INPUT_ALL
	match command_params[0]:
		"NONE":
			mode = escoria.inputs_manager.INPUT_NONE
		"SKIP":
			mode = escoria.inputs_manager.INPUT_SKIP

	escoria.inputs_manager.input_mode = mode
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
