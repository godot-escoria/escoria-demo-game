extends "res://demo/objects/item.gd"

func game_cleared():
	set_state("clear", true)
	if global_id != "":
		vm.register_object(global_id, self)

func set_state(state, p_force = false):
	.set_state(state, p_force)
	printt("set state in telon_music", state)
	print_stack()

func rand_seek(p_node = null):
	if p_node == null:
		p_node = "music"

	var node = get_node(p_node)
	#node.play()
	#return

	var len = node.get_length()
	printt("length is ", len)
	if len == 0:
		return

	var r = randf()
	var pos = len * r
	printt("seek to ", pos, r)

	#if !node.is_playing():
	node.play(pos)
	#node.seek_pos(pos)

func _ready():
	add_to_group("game")

