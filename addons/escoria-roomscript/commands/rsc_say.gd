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
	return say_command.validate(_rewrite_params(arguments))


func run(command_params: Array) -> int:
	return say_command.run(_rewrite_params(command_params))


func get_command_name() -> String:
	return "rsc_say"


static func _rewrite_params(params: Array) -> Array:
	var item_id = params[0]
	var resolved_id = _resolve_item_id(item_id)
	if resolved_id != item_id:
		params[0] = resolved_id
	return params


static func _resolve_item_id(item_id: String) -> String:
	var room = RSCRoom.find_room_for_item(escoria.main.current_scene)
	if room:
		var global_id = room.resolve_item_id(item_id)
		if global_id:
			return global_id
	return item_id
