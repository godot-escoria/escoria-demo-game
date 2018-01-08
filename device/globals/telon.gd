extends "res://globals/item.gd"

var catching_input = false
var item_anim
var item_anim_holder

export var music_volume = 1.0

func set_input_catch(p_catch):
	if catching_input == p_catch:
		return
	#get_node("input_catch").set_ignore_mouse(!p_catch)
	if p_catch:
		get_node("input_catch").set_mouse_filter(Control.MOUSE_FILTER_PASS)
	else:
		get_node("input_catch").set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	catching_input = p_catch
	set_process_input(p_catch)

	return
	var anim = get_node("animation")
	if p_catch:
		anim.play("catch_input")
		set_process_input(true)
	else:
		anim.play("release_input")
		set_process_input(false)
	catching_input = p_catch

func _input(event):
	if event.is_pressed() && event.is_action("ui_accept"):
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "events", "skipped")

func input_event(event):
	if event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "events", "skipped")

func game_cleared():
	if global_id != "":
		vm.register_object(global_id, self)

func set_volume(p_vol):
	# TODO manage multiple buses
	AudioServer.set_bus_volume_db(0, p_vol)

func _process(time):
	set_volume(music_volume)

func global_changed(name):

	return
	#printt("global changed at telon! ", name)
	if name.find("i/") != 0:
		return

	if !vm.get_global(name):
		return

	#if item_anim.is_playing():
	#	return

	# get item by its id?
	var itemid = name.substr(2, name.length() - 2)
	var obj = vm.get_object(itemid)
	if obj == null:
		return
	var item = obj.duplicate()
	item.set_script(null)

	printt("is item ", itemid, item)

	item_anim_holder.add_child(item)
	item.set_position(Vector2(0, 0))
	item.show()
	item_anim.play("new_item")

func item_anim_finished():
	var cur = item_anim.get_current_animation()
	printt("item anim finished at telon ", cur)
	if cur == "new_item":
		while item_anim_holder.get_child_count() > 0:
			var it = item_anim_holder.get_child(0)
			it.free()

func saved():
	#get_node("indicators_anim").play("saved")
	pass

func ui_blocked():
	#get_node("indicators_anim").play("ui_blocked")
	pass

func setup_vm():
	printt("vm on telon is ", vm)
	#vm.connect("global_changed", self, "global_changed")
	vm.connect("saved", self, "saved")
	printt("connected")

func rand_seek(p_node = null):
	if p_node == null:
		p_node = "music"

	var node = get_node(p_node)
	#node.play()
	#return

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

func _ready():
	get_node("input_catch").connect("gui_input", self, "input_event")
	get_node("input_catch").set_size(Vector2(ProjectSettings.get("display/game_width"), ProjectSettings.get("display/game_height")))
	get_node("animation").play("release_input")
	add_to_group("game")

	call_deferred("setup_vm")
	

