# `custom object node func_name [params]`
# 
# Calls the given Godot function on a (child) node of a registered `ESCitem`.
#
# **Parameters**
#
# - *object*: Global ID of the target `ESCItem`
# - *node*: Name of the child node of the target `ESCItem`
# - *func_name*: Name of the function to be called
# - *params*: Any primitive, non-array arguments for the function. Multiple
#   parameters can be passed by using comma-separated values inside a string
#
# @ESC
extends ESCBaseCommand
class_name CustomCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3, 
		[TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_ARRAY],
		[null, null, null, []]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
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
	return .validate(arguments)


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
