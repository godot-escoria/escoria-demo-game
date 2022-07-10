# `custom object node func_name [params...]`
#
#
# Executes the specified Godot function. This function must be in a script
# attached to a child node of a registered `ESCItem`.
#
# **Parameters**
#
# - *object*: Global ID of the target `ESCItem`
# - *node*: Name of the child node of the target `ESCItem`
# - *func_name*: Name of the function to be called
# - params: Any arguments to be passed to the function (array and object parameters are not supported).
# Multiple parameters can be passed by simply passing them in as additional arguments separated by
# spaces, e.g. `custom the_object the_node the_function arg1 arg2 arg3`
#
# @ESC
extends ESCBaseCommand
class_name CustomCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3,
		[TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_ARRAY],
		[null, null, null, []],
		[true],
		true
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.error(
			self,
			"[%s]: invalid object. Object with global id %s not found."
					% [get_command_name(), arguments[0]]
		)
		return false
	elif not escoria.object_manager.get_object(arguments[0]).node.has_node(
		arguments[1]
	):
		escoria.logger.error(
			self,
			"[%s]: invalid node. Object with global id %s has no child node called %s."
					% [
						get_command_name(),
						arguments[0],
						arguments[1],
					]
		)
		return false
	elif not escoria.object_manager.get_object(arguments[0]).node\
		.get_node(
			arguments[1]
		)\
		.has_method(
			arguments[2]
		):
		escoria.logger.error(
			self,
			"[%s]: invalid function. Object with global id %s and node %s has no function called %s."
					% [
						get_command_name(),
						arguments[0],
						arguments[1],
						arguments[2],
					]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	var object = escoria.object_manager.get_object(
		command_params[0]
	)
	# Global variables can be substituted into the command arguments by wrapping the global
	# name in braces.
	for loop in command_params[3].size():
		command_params[3][loop] = escoria.globals_manager.replace_globals(command_params[3][loop])

	object.node.get_node(command_params[1]).call(
		command_params[2],
		command_params[3]
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.warn(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
