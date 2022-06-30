extends Node
class_name RSCTeleportCommand


var teleport_command = TeleportCommand.new()


func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING],
		[null, null]
	)


func validate(arguments: Array) -> bool:
	RSCRoom.rewrite_command_params(arguments, 0)
	RSCRoom.rewrite_command_params(arguments, 1)
	return teleport_command.validate(arguments)


func run(command_params: Array) -> int:
	RSCRoom.rewrite_command_params(command_params, 0)
	RSCRoom.rewrite_command_params(command_params, 1)
	return teleport_command.run(command_params)


func get_command_name() -> String:
	return "rsc_teleport"
