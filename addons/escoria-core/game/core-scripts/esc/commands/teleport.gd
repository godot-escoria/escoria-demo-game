# `teleport object target`
#
# Moves an object directly to a new position
#
# **Parameters**
#
# - *object*: Global ID of the object to move
# - *target*: Global ID of the target object
#
# @ESC
extends ESCBaseCommand
class_name TeleportCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING],
		[null, null]
	)
	
	
# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"teleport: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false	
	if not escoria.object_manager.objects.has(arguments[1]):
		escoria.logger.report_errors(
			"teleport: invalid second object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCPlayer)\
		.teleport(
			escoria.object_manager.get_object(command_params[1]).node
		)
	return ESCExecution.RC_OK
