extends Node

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
	telon.set_input_catch(p_catch)

func clear_scene():
	if current == null:
		return

	get_node("/root").remove_child(current)
	current.free()
	current = null

func set_scene(p_scene, run_events=true):
	assert p_scene

	## Uncomment this as a starting point in case of trouble,
	## but it occurs that yielding here will cause lag and apparently
	## serves no real purpose
	# Like `:open` from a door in the last room
	# if vm.running_event:
	# 	yield(vm, "event_done")

	if "events_path" in p_scene and p_scene.events_path and run_events:
		vm.load_file(p_scene.events_path)

		# :setup is pretty much required in the code, but fortunately
		# we can help out with cases where one isn't necessary otherwise
		if not "setup" in vm.game:
			var fake_setup = vm.compile_str(":setup\n")
			vm.game["setup"] = fake_setup["setup"]

		vm.run_event(vm.game["setup"])

	if current != null:
		clear_scene()

	get_node("/root").add_child(p_scene)

	set_current_scene(p_scene, run_events)

func get_current_scene():
	return current

func menu_open(menu):
	menu_stack.push_back(menu)
	if menu_stack.size() == 1:
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "menu_opened")
		vm.set_pause(true)
		#get_tree().set_pause(true)
		pass

func menu_close(p_menu):
	if menu_stack.size() == 0 || menu_stack[menu_stack.size()-1] != p_menu:
		print("***** warning! closing unknown menu?")
	menu_stack.remove(menu_stack.size() - 1)

	if menu_stack.size() == 0:
		vm.set_pause(false)
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "menu_closed")
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

func set_current_scene(p_scene, run_events=true):
	#print_stack()
	# printt("set_current_scene: ", p_scene, run_events)
	current = p_scene
	get_node("/root").move_child(current, 0)

	# Loading a save game must set the scene but not run events
	if "events_path" in current and current.events_path and run_events:
		if vm.game:
			# Having a game with `:setup` means we must wait for it to finish
			if "setup" in vm.game:
				assert vm.running_event
				assert vm.running_event.ev_name == "setup"
				yield(vm, "event_done")
		else:
			vm.load_file(current.events_path)
			# For a new game, we must run `:setup` if available
			# and wait for it to finish
			if "setup" in vm.game:
				vm.run_event(vm.game["setup"])
				yield(vm, "event_done")

		# Because 1) changing a scene and 2) having a scene become ready
		# both call `set_current_scene`, we don't want to duplicate thing
		if not vm.running_event:
			vm.run_game()

func wait_finished():
	vm.finished(wait_level)

func wait(time, level):
	wait_level = level
	wait_timer.set_wait_time(time)
	wait_timer.set_one_shot(true)
	wait_timer.start()

func _input(event):
	# CTRL+F12
	if (event is InputEventKey and event.pressed and event.control and event.scancode==KEY_F12):
		OS.print_all_textures_by_size()

	if menu_stack.size() > 0:
		menu_stack[menu_stack.size() - 1].input(event)
	elif current != null:
		if current.has_node("game"):
			current.get_node("game").scene_input(event)

func load_telon():
	var tpath = ProjectSettings.get_setting("escoria/platform/telon")
	var tres = vm.res_cache.get_resource(tpath)

	get_node("layers/telon/telon").replace_by_instance(tres)
	telon = get_node("layers/telon/telon")

func _ready():
	printt("main ready")
#	get_node("/root").set_render_target_clear_on_new_frame(true)

	game_size = get_viewport().size

	wait_timer = get_node("layers/wait_timer")
	if wait_timer != null:
		wait_timer.connect("timeout", self, "wait_finished")
	add_to_group("game")
	menu_layer = get_node("layers/menu")
	set_process_input(true)
	set_process(true)

	ProjectSettings.load_resource_pack("res://scripts.zip")

	call_deferred("load_telon")
