## `custom(object: String, node: String, func_name: String[, params...])`
##
## Executes the specified Godot function. This function must be in a script attached to a child node of a registered `ESCItem`.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Global ID of the target `ESCItem`|yes|[br]
## |node|`String`|Name of the child node of the target `ESCItem`|yes|[br]
## |func_name|`String`|Name of the function to be called|yes|[br]
## |params...|`Variant`|Optional arguments passed to the target function (arrays and objects are not supported). Additional positional parameters can be listed after the required ones, e.g. `custom("the_object", "the_node", "the_function", arg1, arg2)`.|no|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name CustomCommand


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
		[TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_ARRAY],
		[null, null, null, []],
		[true],
		true
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
		raise_invalid_object_error(self, arguments[0])
		return false
	elif not escoria.object_manager.get_object(arguments[0]).node.has_node(
		arguments[1]
	):
		raise_error(self, "Invalid node. Object with global id %s has no child node called %s."
					% [
						arguments[0],
						arguments[1],
					])
		return false
	elif not escoria.object_manager.get_object(arguments[0]).node\
		.get_node(
			arguments[1]
		)\
		.has_method(
			arguments[2]
		):
		raise_error(self, "Invalid function. Object with global id %s and node %s has no function called %s."
					% [
						arguments[0],
						arguments[1],
						arguments[2],
					])

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
	var object = escoria.object_manager.get_object(
		command_params[0]
	)
	# Global variables can be substituted into the command arguments by wrapping the global
	# name in braces.
	for loop in command_params[3].size():\
		if typeof(command_params[3][loop]) == TYPE_STRING:
			command_params[3][loop] = escoria.globals_manager.replace_globals(command_params[3][loop])

	object.node.get_node(command_params[1]).call(
		command_params[2],
		command_params[3]
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
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
