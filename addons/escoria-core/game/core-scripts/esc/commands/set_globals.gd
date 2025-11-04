## `set_globals(pattern: String, value: String|Integer|Boolean)`
##
## Changes the value of multiple globals using a wildcard pattern, where `*` matches zero or more arbitrary characters and `?` matches any single character except a period (".").[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |pattern|`String`|Pattern to use to match the names of the globals to change|yes|[br]
## |value|`String` or `Integer` or `Boolean`|Value to set (can be of type string, boolean, integer or float)|yes|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name SetGlobalsCommand


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
		[TYPE_STRING, [TYPE_BOOL, TYPE_STRING, TYPE_INT]],
		[null, null]
	)


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
	escoria.globals_manager.set_global_wildcard(
		command_params[0],
		command_params[1]
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
