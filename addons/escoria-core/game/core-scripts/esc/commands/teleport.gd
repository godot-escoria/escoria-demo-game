# `teleport object1 object2 [angle]`
#
# Sets the position of object1 to the position of object2. By default,
# object2's interact_angle is used to turn object1, but angle will override 
# this. Useful for doors and such with an interact_angle you don't always want 
# to adhere to when re-entering a room.
#
# @ESC
extends ESCBaseCommand
class_name TeleportCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_INT],
		[null, null, null]
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
	escoria.object_manager.get_object(command_params[0]).node\
		.teleport(
			escoria.object_manager.get_object(command_params[1]).node, 
			command_params[2]
		)
	return ESCExecution.RC_OK
