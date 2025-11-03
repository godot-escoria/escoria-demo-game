## `set_global(name: String, value: String|Integer|Boolean[, force: Boolean=false])`
##
## Changes the value of a global.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |name|`String`|Name of the global variable to set.|yes|[br]
## |value|`String` or `Integer` or `Boolean`|Value to set the global to (can be of type string, boolean, integer or float)|yes|[br]
## |force|`Boolean`|if false, setting a global whose name is reserved will trigger an error. Defaults to false. Reserved globals are: ESC_LAST_SCENE, FORCE_LAST_SCENE_NULL, ANIMATION_RESOURCES, ESC_CURRENT_SCENE|no|[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name SetGlobalCommand

## The list of illegal strings that cannot be used in global names.
const ILLEGAL_STRINGS = ["/"]


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
		2,
		[TYPE_STRING, [TYPE_INT, TYPE_BOOL, TYPE_STRING], TYPE_BOOL],
		[null, null, false]
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

	for s in ILLEGAL_STRINGS:
		if s in arguments[0]:
			raise_error(
				self,
				"Invalid global variable. Global variable '%'s cannot contain the string '%s'."
					% [arguments[0], s]
			)
			return false

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
	escoria.globals_manager.set_global(
		command_params[0],
		command_params[1],
		command_params[2]
	)
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
	# Do nothing
	pass
