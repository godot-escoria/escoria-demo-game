extends Control

onready var white = $"white"

var animation
var anim_notify

export var global_id = "telon"

func set_input_disabled(p_input_disabled):
	$"/root".set_disable_input(p_input_disabled)
	vm.set_global("save_disabled", str(p_input_disabled))
	vm.report_warnings("telon", ["Deprecated interface, use 'accept_input NONE' instead"])

func game_cleared():
	self.disconnect("tree_exited", vm, "object_exit_scene")
	vm.register_object(global_id, self)

#warning-ignore:unused_argument
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
	var conn_err = vm.connect("saved", self, "saved")
	if conn_err:
		vm.report_errors("telon", ["saved -> saved error: " + String(conn_err)])
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

## Have the unused arguments because API
#warning-ignore:unused_argument
#warning-ignore:unused_argument
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
	var conn_err

	animation = $"animation"

	vm.register_object(global_id, self)

	conn_err = animation.connect("animation_finished", self, "anim_finished")
	if conn_err:
		vm.report_errors("telon", ["animation_finished -> anim_finished error: " + String(conn_err)])

	add_to_group("game")

	call_deferred("setup_vm")

