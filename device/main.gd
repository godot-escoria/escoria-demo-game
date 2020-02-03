extends Node

var vm
var telon
var menu_layer
var wait_timer
var wait_level
var current
var menu_stack = []
var vm_size = Vector2(0, 0)
var game_size
var screen_ofs = Vector2(0, 0)

func set_input_catch(p_catch):
	telon.call_deferred("set_input_catch", p_catch)

func clear_scene():
	if current == null:
		return

	var root = get_tree().get_root()
	root.remove_child(current)
	current.free()
	current = null

func set_scene(p_scene):
	if current != null:
		clear_scene()

	if !p_scene:
		return
	var root = get_tree().get_root()
	root.add_child(p_scene)
	set_current_scene(p_scene)

func get_current_scene():
	return current

func menu_open(menu):
	menu_stack.push_back(menu)
	if menu_stack.size() == 1:
		get_tree().call_group("game", "menu_opened")
		vm.set_pause(true)
		#get_tree().set_pause(true)
		pass

func menu_close(p_menu):
	if menu_stack.size() == 0 || menu_stack[menu_stack.size()-1] != p_menu:
		print("***** warning! closing unknown menu?")
	menu_stack.remove(menu_stack.size() - 1)

	if menu_stack.size() == 0:
		vm.set_pause(false)
		get_tree().call_group("game", "menu_closed")
		#get_tree().set_pause(false)
		pass

func load_menu(path):
	if path == "":
		printt("error: loading empty menu")
		return
	var menu = load(path)
	if menu == null:
		printt("error loading menu ", path)
		return
	printt("************* loding menu ", path, menu)
	menu = menu.instance()
	menu_layer.add_child(menu)
	return menu

func menu_collapse():
	var i = menu_stack.size()
	while i > 0:
		i -= 1
		menu_stack[i].menu_collapsed()

func set_current_scene(p_scene):
	#print_stack()
	current = p_scene
	var root = get_tree().get_root()
	root.move_child(p_scene, 0)

func wait_finished():
	vm.finished(wait_level)

func wait(time, level):
	wait_level = level
	wait_timer.set_wait_time(time)
	wait_timer.set_one_shot(true)
	wait_timer.start()

func check_screen():
	var vs = OS.get_screen_size()
	if vs == vm_size:
		return
	vm_size = vs

	var rate = float(vs.x)/float(vs.y)
	var height = int(game_size.x / rate)
	get_tree().get_root().set_size_override(true,Vector2(game_size.x,height))
	get_tree().get_root().set_size_override_stretch(true)

	var m = Transform2D()
	var ofs = Vector2(0, (height - game_size.y) / 2)
	m[2] = ofs
	get_tree().get_root().set_global_canvas_transform(m)

	screen_ofs = ofs
	printt("**** screen ofs is ", screen_ofs)

	#get_tree().set_auto_accept_quit(false)

	get_tree().call_group("game", "set_camera_limits")


func _process(_time):
	check_screen()

func _input(event):
	if (event is InputEventKey and event.pressed and event.control and event.scancode==KEY_F12):
		OS.print_all_textures_by_size()
		
	if menu_stack.size() > 0:
		menu_stack[menu_stack.size() - 1].input(event)
	elif current != null:
		if current.has_node("game"):
			current.get_node("game").call_deferred("scene_input", event)

func load_telon():
	var tpath = ProjectSettings.get("platform/telon")
	var tres = vm.res_cache.get_resource(tpath)

	get_node("layers/telon/telon").replace_by_instance(tres)
	telon = get_node("layers/telon/telon")

func _ready():

	printt("main ready")
	#get_node("/root").set_render_target_clear_on_new_frame(true)

	game_size = Vector2()
	game_size.x = ProjectSettings.get("display/game_width")
	game_size.y = ProjectSettings.get("display/game_height")

	vm = get_tree().get_root().get_node("vm")
	wait_timer = get_node("layers/wait_timer")
	wait_timer.connect("timeout", self, "wait_finished")
	add_to_group("game")
	menu_layer = get_node("layers/menu")
	set_process_input(true)
	set_process(true)

	# warning-ignore:return_value_discarded
	ProjectSettings.load_resource_pack("res://scripts.zip")

	call_deferred("load_telon")

