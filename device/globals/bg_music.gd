extends "res://globals/item.gd"

var stream

func game_cleared():
	set_state("off", true)
	if global_id != "":
		vm.register_object(global_id, self)

func set_state(p_state, p_force = false):

	# Can't do anything without a player
	if stream == null:
		return

	# If already playing this stream, keep playing, unless p_force
	if p_state == state and not p_force and stream.is_playing():
		return

	# Update state in base class
	.set_state(p_state, p_force)

	# If state is "off"/"default", turn off music
	if state == "off" or state == "default":
		stream.stream = null
		return

	var resource = load(p_state)

	stream.stream = resource

	if stream.stream:
		resource.set_loop(true)
		stream.play()
		stream.volume_db = vm.settings.music_volume

func load_stream():
	stream = get_node("stream")

func _ready():
	call_deferred("load_stream")