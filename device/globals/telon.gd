extends Control

onready var white = $"white"

var animation
var anim_notify
var item_anim
var item_anim_holder

var catching_input = false

export var global_id = "telon"

func set_input_catch(p_catch):
	if catching_input == p_catch:
		return

	if p_catch:
		# When catching, assume we can handle the event in `input_event`
		get_node("input_catch").set_mouse_filter(Control.MOUSE_FILTER_PASS)
	else:
		# When released, allow some other node to handle the click
		get_node("input_catch").set_mouse_filter(Control.MOUSE_FILTER_IGNORE)

	catching_input = p_catch
	set_process_input(p_catch)

func set_input_disabled(p_input_disabled):
	$"/root".set_disable_input(p_input_disabled)
	vm.set_global("save_disabled", str(p_input_disabled))

func _input(event):
	if event.is_pressed() && event.is_action("ui_accept"):
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "events", "skipped")

func input_event(event):
	if event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "events", "skipped")

func game_cleared():
	self.disconnect("tree_exited", vm, "object_exit_scene")
	vm.register_object(global_id, self)

func anim_finished(anim_name):
	if anim_notify != null:
		vm.finished(anim_notify)
		anim_notify = null

func saved():
	## XXX: This should be implemented somewhere in the game data tree!
	#get_node("indicators_anim").play("saved")
	pass

func ui_blocked():
	## XXX: This should be implemented somewhere in the game data tree!
	#get_node("indicators_anim").play("ui_blocked")
	pass

func setup_vm():
	printt("vm on telon is ", vm)
	vm.connect("saved", self, "saved")
	printt("connected")

func rand_seek(p_node = null):
	if p_node == null:
		p_node = "music"

	var node = get_node(p_node)

	var length = node.get_length()
	printt("length is ", length)
	if length == 0:
		return

	var r = randf()
	var pos = length * r
	printt("seek to ", pos, r)

	node.seek_pos(pos)
	if !node.is_playing():
		node.play()

func telon_play_anim(p_anim):
	# Play animations like `get_tree().call_group("game", "telon_play_anim", "fade_in")`
	animation.play(p_anim)

func play_anim(p_anim, p_notify = null, p_reverse = false, p_flip = null):
	# A simple wrapper that implements the `cut_scene`/`anim` API
	anim_notify = p_notify
	return telon_play_anim(p_anim)

func cut_to_black():
	white.visible = true
	white.self_modulate = "000000"
	white.modulate = "ffffff"

func cut_to_scene():
	white.visible = false

func _ready():
	animation = $"animation"

	vm.register_object(global_id, self)

	animation.connect("animation_finished", self, "anim_finished")

	get_node("input_catch").connect("gui_input", self, "input_event")
	get_node("input_catch").set_size(get_viewport().size)

	add_to_group("game")

	call_deferred("setup_vm")

