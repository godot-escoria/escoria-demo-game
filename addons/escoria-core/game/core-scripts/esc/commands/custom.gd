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
		escoria.logger.report_errors(
			"custom: invalid object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	elif not escoria.object_manager.get_object(arguments[0]).node.has_node(
		arguments[1]
	):
		escoria.logger.report_errors(
			"custom: invalid node",
			[
				"Object with global id %s has no node %s" % [
					arguments[0],
					arguments[1],
				]
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
		escoria.logger.report_errors(
			"custom: invalid function",
			[
				"Object with global id %s and node %s has no function %s" % [
					arguments[0],
					arguments[1],
					arguments[2],
				]
			]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	var object = escoria.object_manager.get_object(
		command_params[0]
	)
	object.node.get_node(command_params[1]).call(
		command_params[2],
		command_params[3]
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.report_warnings(
		get_command_name(),
		[
			"Interrupt() function not implemented"
		]
	)
