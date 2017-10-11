extends "res://globals/item.gd"

onready var stream = get_node("stream")
var current_music

func game_cleared():
	set_state("off", true)
	if global_id != "":
		vm.register_object(global_id, self)

func set_state(p_state, p_force = false):

	if p_state == state && !p_force && stream.is_playing():
		return

	#set_state(p_state, p_force)

	if stream == null:
		return

	if state == "off" || state == "default":
		stream.set_stream(null)
		return

	var res = load(p_state)
	stream.set_stream(res)
	if res != null:
		stream.set_loop(true)
		stream.play()
		stream.set_volume(vm.settings.music_volume)
