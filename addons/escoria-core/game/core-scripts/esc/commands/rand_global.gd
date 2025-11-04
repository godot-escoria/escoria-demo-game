## `rand_global(name: String, max_value: Integer)`
##
## Sets the given global to a random integer between 0 and `max_value` (inclusive). e.g. Setting `max_value` to 2 could result in '0', '1' or '2' being returned.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |name|`String`|Name of the global variable that will receive the random value.|yes|[br]
## |max_value|`Integer`|Maximum possible integer value (inclusive) (default: 1)|yes|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name RandGlobalCommand


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
		1,
		[TYPE_STRING, TYPE_INT],
		[null, 1]
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
func validate(arguments: Array) -> bool:
	if not super.validate(arguments):
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
	randomize()
	var rnd = randi() % (int(command_params[1]) + 1)
	escoria.globals_manager.set_global(
		command_params[0],
		rnd
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
