# `rsc_say item text [type]`
#
# Same as `say` except `item` can be a local name that is resolved if the
# current room is an RSCRoom.
#
# @ESC
extends Node
class_name RSCSayCommand

var say_command = SayCommand.new()


func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_STRING],
		[
			null,
			null,
			""
		],
		[
			true,
			false,
			true
		]
	)


func validate(arguments: Array) -> bool:
	return say_command.validate(RSCRoom.rewrite_command_params(arguments, 0))


func run(command_params: Array) -> int:
	return say_command.run(RSCRoom.rewrite_command_params(command_params, 0))


func get_command_name() -> String:
	return "rsc_say"
