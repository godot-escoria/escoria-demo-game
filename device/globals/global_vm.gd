extends Node

var stack = []
var globals = {}
var objects = {}

var event_queue = []

var state_return = 0
var state_yield = 1
var state_break = 2
var state_repeat = 3
var state_call = 4
var state_jump = 5

var states = {}
var actives = {}

var vm_size = Vector2(0, 0)
var game_size

var compiler
var level

var root
var res_cache

var cam_target = null
var cam_speed = 0
var camera
var camera_limits

var drag_object = null
var hover_object = null

var last_autosave = 0
var autosave_pending = false
const AUTOSAVE_TIME_MS = 64 * 1000

var save_data

var continue_enabled = true

var focus_pause = false

var loading_game = false
var achievements = null
var rate_url = ""

var settings_default = {
	"text_lang": "en",
	"voice_lang": "en",
	"music_volume": 1,
	"sfx_volume": 1,
	"voice_volume": 1,
	"fullscreen": false,
	"skip_dialog": true,
	"rate_shown": false,
}


var scenes_cache_list = preload("res://game/scenes_cache.gd").scenes

var scenes_cache = {} # this will eventually have everything in scenes_cache_list forever

var settings

func save_settings():
	save_data.save_settings(settings, null)

func load_settings():
	save_data.load_settings([self, "settings_loaded"])

func settings_loaded(p_settings):
	printt("******* settings loaded")
	settings_default.text_lang = OS.get_locale().substr(0, 2)
	if p_settings != null:
		settings = p_settings
	else:
		settings = {}

	for k in settings_default:
		if !(k in settings):
			settings[k] = settings_default[k]

	AudioServer.set_fx_global_volume_scale(settings.sfx_volume)
	TranslationServer.set_locale(settings.text_lang)
	music_volume_changed()
	update_window_fullscreen(true)

func update_window_fullscreen(p_force = false):
	if Globals.get("debug/screen_size_override"):
		return
	if !p_force && (settings.fullscreen == OS.is_window_fullscreen()):
		return
	if settings.fullscreen:
		OS.set_window_resizable(true)
		OS.set_window_fullscreen(settings.fullscreen)
		pass
	else:
		var title = Globals.get("platform/window_title_height")
		var sc = OS.get_current_screen()
		var ratio = 1080 / 1920.0
		var size = OS.get_screen_size(sc)
		printt("***** got screen size ", size, title)
		var h = size.y - title
		if h / ratio > size.x:
			size.y = size.x * ratio
		else:
			size.y = size.y - title
			size.x = h / ratio
		printt("setting window to size", size)
		OS.set_window_fullscreen(settings.fullscreen)
		OS.set_window_size(size)
		#OS.set_window_position(Vector2(0, 0))
		OS.set_window_resizable(Globals.get("platform/screen_resizable"))

func music_volume_changed():
	emit_signal("music_volume_changed")


func drag_begin(obj_id):
	drag_object = obj_id

func drag_end():
	if drag_object != null:
		# dragging ends
		printt("********** dragging ends")
		if hover_object != null && !hover_object.inventory:
			printt("calling clicked")
			get_tree().call_group(0, "game", "clicked", hover_object, hover_object.get_pos())
			get_tree().call_group(0, "game", "clear_pending_command")
		elif hover_object == null:
			get_tree().call_group(0, "game", "clear_pending_command")
			get_tree().call_group(0, "hud", "set_tooltip", "")

	drag_object = null

func hover_begin(obj):
	hover_object = obj

func hover_end():
	hover_object = null

func update_camera(time):
	if camera == null:
		return
	var target = cam_target
	if target == null:
		target = get_object("player")

	if target == null:
		target = Vector2(0, 0)

	var pos
	if typeof(target) == typeof(Vector2()):
		pos = target
	elif typeof(target) == typeof([]):
		var count = 0
		pos = Vector2()
		for n in target:
			var obj = get_object(n)
			if obj != null:
				count += 1
				pos += obj.get_pos()
		if count > 0:
			pos = pos / count
	else:
		pos = target.get_pos()

	var cpos = camera.get_pos()

	if cpos != pos:
		#return

		var dif = pos - cpos
		var dist = cam_speed * time
		if dist > dif.length() || cam_speed == 0:
			camera.set_pos(pos)
			#return
		else:
			camera.set_pos(cpos + dif.normalized() * dist)
			pos = cpos + dif.normalized() * dist

	if Globals.get("platform/use_custom_camera"):
		var half = game_size / 2
		pos = _adjust_camera(pos)
		var t = Matrix32()
		t[2] = (-(pos - half))

		get_node("/root").set_canvas_transform(t)

func _adjust_camera(pos):
	var half = game_size / 2

	if pos.x + half.x > camera_limits.pos.x + camera_limits.size.x:
		pos.x = (camera_limits.pos.x + camera_limits.size.x) - half.x
	if pos.x - half.x < camera_limits.pos.x:
		pos.x = camera_limits.pos.x + half.x

	if pos.y + half.y > camera_limits.pos.y + camera_limits.size.y:
		pos.y = (camera_limits.pos.y + camera_limits.size.y) - half.y
	if pos.y - half.y < camera_limits.pos.y:
		pos.y = camera_limits.pos.y + half.y

	return pos

func set_cam_limits(limits):
	camera_limits = limits

func camera_set_target(speed, p_target):
	cam_speed = speed
	cam_target = p_target

func inventory_has(p_obj):
	return get_global("i/"+p_obj)

func inventory_set(p_obj, p_has):
	set_global("i/"+p_obj, p_has)

func say(params, level):
	get_tree().call_group(0, "dialog", "say", params, level)

func dialog_config(params):
	get_tree().call_group(0, "dialog", "config", params)

func wait(params, level):
	var time = float(params[0])
	printt("wait time ", params[0], time)
	if time <= 0:
		return state_return
	get_tree().call_group(0, "game", "wait", time, level)
	level.waiting = true
	return state_yield

func test(cmd):
	if "if_true" in cmd:
		for flag in cmd.if_true:
			if !get_global(flag):
				return false
	if "if_false" in cmd:
		for flag in cmd.if_false:
			if get_global(flag):
				return false
	if "if_inv" in cmd:
		for flag in cmd.if_inv:
			if !inventory_has(flag):
				return false
	if "if_not_inv" in cmd:
		for flag in cmd.if_not_inv:
			if inventory_has(flag):
				return false

	return true

func dialog(params, level):
	get_tree().call_group(0, "dialog_dialog", "start", params, level)

func instance_level(p_level, p_root):
	var level = { "ip": 0, "instructions": p_level, "waiting": false, "break_stop": p_root, "labels": {} }
	for i in range(p_level.size()):
		if p_level[i].name == "label":
			var lname = p_level[i].params[0]
			level.labels[lname] = i
	return level

func compile(p_path):

	var ev_table

	if p_path.find(".gd") != -1:
		var res = ResourceLoader.load(p_path)
		if res == null:
			return null
		ev_table = res.new().get_events()
	else:
		var errors = []
		ev_table = compiler.compile(p_path, errors)
		if errors.size() > 0:
			call_deferred("report_errors", p_path, errors)

	return ev_table

func compile_str(p_str):
	var errors = []
	var ev_table = compiler.compile_str(p_str, errors)
	if errors.size() > 0:
		call_deferred("report_errors", "[string]", errors)

	return ev_table

func report_errors(p_path, errors):
	#var dialog = preload("res://game/globals/errors.xml").instance()
	var text = "Errors in file "+p_path+"\n\n"
	for e in errors:
		text += e+"\n"
	#dialog.set_text(text)
	print("error is ", text)
	#root.get_node("layers/telon").add_child(dialog)

func add_level(p_level, p_root):
	stack.push_back(instance_level(p_level, p_root))
	return state_call
	#run()
	#var ret =  run_top()
	#return ret

func run_event(p_event):
	root.set_input_catch(true)
	get_tree().call_group(0, "hud", "set_tooltip", "")
	add_level(p_event, true)

func sched_event(time, obj, event):
	event_queue.push_back([time, obj, event])

func get_global(name):
	return (name in globals) && globals[name]

func set_global(name, val):
	globals[name] = val
	#printt("global changed at global_vm, emitting for ", name, val)
	emit_signal("global_changed", name)

func set_globals(pat, val):
	for key in globals:
		if key.match(pat):
			globals[key] = val
			emit_signal("global_changed", key)

func get_global_list():
	return globals.keys()

func get_object(name):
	if !(name in objects):
		return null
	return objects[name]

func register_object(name, val):
	objects[name] = val
	if name in states:
		val.set_state(states[name])
	else:
		val.set_state("default")
	if name in actives:
		val.set_active(actives[name])
	val.connect("exit_tree", self, "object_exit_scene", [name])

func get_registered_objects():
	return objects

func set_state(name, state):
	states[name] = state

func set_active(name, active):
	actives[name] = active

func object_exit_scene(name):
	objects.erase(name)

func check_event_queue(time):
	for e in event_queue:
		if e[0] > 0:
			e[0] -= time

	if !can_interact():
		return

	var i = event_queue.size()
	while i:
		i -= 1
		if event_queue[i][0] <= 0:
			var obj = get_object(event_queue[i][1])
			run_event(obj.event_table[event_queue[i][2]])
			event_queue.remove(i)
			break

func _process(time):
	check_event_queue(time)
	run()
	check_autosave()
	update_camera(time)

func run_top():
	var top = stack[stack.size()-1]
	var ret = level.resume(top)
	if ret == state_return || ret == state_break:
		stack.remove(stack.size()-1)
	return ret

func jump(p_label):
	while stack.size() > 0:
		var top = stack[stack.size()-1]
		printt("top labels: ", top.labels, p_label)
		if p_label in top.labels:
			top.ip = top.labels[p_label]
			return
		else:
			if top.break_stop || stack.size() == 1:
				report_errors("", ["Label not found: "+p_label+", can't jump"])
				stack.remove(stack.size()-1)
				break
			else:
				stack.remove(stack.size()-1)

func run():
	if stack.size() == 0:
		return
	while stack.size() > 0:
		var ret = run_top()
		if ret == state_yield:
			return
		if ret == state_break:
			while stack.size() > 0 && !(stack[stack.size()-1].break_stop):
				stack.remove(stack.size()-1)
			stack.remove(stack.size()-1)
	root.set_input_catch(false)
	loading_game = false

func can_save():
	return can_interact() && !get_global("save_disabled")

func menu_enabled():
	printt("*** menu disabled is ", get_global("menu_disabled"))
	return !get_global("menu_disabled")

func can_interact():
	return stack.size() == 0

func finished(context):
	context.waiting = false

func change_scene(params, context):
	printt("change scene to ", params[0])
	#var res = ResourceLoader.load(params[0])
	check_cache()
	root.clear_scene()
	camera = null
	event_queue = []
	var res = res_cache.get_resource(params[0])
	res_cache.clear()
	var scene = res.instance()
	if scene:
		root.set_scene(scene)
	else:
		report_errors("", ["Failed loading scene "+params[0]+" for change_scene"])

	if context != null:
		context.waiting = false

	camera_set_target(0, null)
	autosave_pending = true

func swap_scene(p_path):

	var res = res_cache.get_resource(p_path)
	root.clear_scene()
	var scene = res.instance()
	if scene:
		root.set_scene(scene)
	else:
		report_errors("", ["Failed loading scene "+p_path+" for swap_scene"])

func spawn(params):
	var res = ResourceLoader.load(params[0])
	var scene = res.instance()
	if scene:
		root.get_tree().add_child(scene)
	else:
		report_errors("", ["Failed loading scene "+params[0]+" for spawn"])
		return state_return
	if params.size() > 1:
		var obj = get_object(params[1])
		if obj:
			scene.set_pos(obj.get_global_pos());
		else:
			report_errors("", ["Global id "+params[1]+" not found for spawn"])
	return state_return

func request_autosave():
	autosave_pending = true


func set_pause(p_pause):
	get_tree().set_pause(p_pause)
	emit_signal("paused", p_pause)

func is_game_active():
	return root.get_current_scene() != null && (root.get_current_scene() extends preload("res://globals/scene.gd"))

func check_autosave():
	if get_global("save_disabled"):
		return
	if root.get_current_scene() == null || !(root.get_current_scene() extends preload("res://globals/scene.gd")):
		return
	var time = OS.get_ticks_msec()
	if autosave_pending || (time - last_autosave) > AUTOSAVE_TIME_MS:
		autosave_pending = true
		var data = save()
		if data == false:
			return
		autosave_pending = false
		save_data.autosave(data, [self, "autosave_done"])

func autosave_done(err):
	if err != OK:
		return
	last_autosave = OS.get_ticks_msec()

func check_cache():
	for s in scenes_cache_list:
		if s in scenes_cache:
			continue
		scenes_cache[s] = res_cache.get_resource(s)

func load_file(p_game):
	var f = File.new()
	if !f.file_exists(p_game):
		return

	var game = compile(p_game)
	clear()
	loading_game = true
	run_event(game["load"])
	root.menu_collapse()

func load_slot(p_game):
	var cb = [self, "game_str_loaded"]
	save_data.load_slot(p_game, cb)

func load_autosave():
	printt("calling load autosave")
	save_data.load_autosave([self, "game_str_loaded"])

func game_str_loaded(p_data = null):
	if p_data == null:
		return

	var game = compile_str(p_data)
	clear()
	loading_game = true
	run_event(game["load"])
	root.menu_collapse()

func save():
	if stack.size() != 0:
		return false

	var ret = []

	ret.append(":load\n\n")

	ret.append("cut_scene telon fade_out\n\n")

	ret.append("## Global flags\n\n")
	for k in globals.keys():
		if !globals[k]:
			continue
		ret.append("set_global " + k + " true\n")
	ret.append("\n")

	ret.append("## Objects\n\n")
	var objs = {}
	for k in states.keys():
		objs[k] = true
	for k in actives.keys():
		objs[k] = true
	for k in objs.keys():
		if k in actives:
			var s = "true"
			if !actives[k]:
				s = "false"
			ret.append("set_active " + k + " " + s + "\n")

		if k in states && states[k] != "default":
			ret.append("set_state " + k + " " + states[k] + "\n")

		ret.append("\n")

	# check global states of moved objects
	#for k in objects:
	#	if k == "player" || objects[k] == null:
	#		continue
	#	if objects[k].moved:
	#		var pos = objects[k].get_pos()
	#		ret.append("teleport_pos " + k + " " + str(int(pos.x)) + " " + str(int(pos.y)) + "\n")

	ret.append("\n")
	ret.append("## Player\n\n")

	ret.append("change_scene " + root.get_current_scene().get_filename() + "\n")

	if root.get_current_scene().has_node("player"):
		var pos = root.get_current_scene().get_node("player").get_global_pos()
		ret.append("teleport_pos player " + str(pos.x) + " " + str(pos.y) + "\n")

	if cam_target != null:
		ret.append("\n")
		ret.append("## Camera\n\n")
		if typeof(cam_target) == typeof(Vector2()):
			#ret.append("camera_set_pos " + str(cam_speed) + " " + str(int(cam_target.x)) + " " + str(int(cam_target.y)) + "\n")
			ret.append("camera_set_pos 0 " + str(int(cam_target.x)) + " " + str(int(cam_target.y)) + "\n")
		else:
			var tlist = ""

			if typeof(cam_target) == typeof([]):
				for t in cam_target:
					tlist = tlist + " " + t
			else:
				tlist = tlist + " " + cam_target


			ret.append("camera_set_target 0" + tlist + "\n")
			ret.append("camera_set_target " + str(cam_speed) + tlist + "\n")

	for e in event_queue:
		ret.append("sched_event " + str(e[0]) + " " + str(e[1]) + " " + str(e[2]) + "\n")

	ret.append("\ncut_scene telon fade_in\n")

	emit_signal("saved")

	return ret

func set_camera(p_cam):
	camera = p_cam
	if Globals.get("platform/use_custom_camera"):
		camera.clear_current()

func clear():
	get_tree().call_group(0, "game", "game_cleared")
	stack = []
	globals = {}
	objects = {}
	states = {}
	actives = {}
	event_queue = []
	continue_enabled = true
	loading_game = false

func game_over(p_enable_continue, p_show_credits, context):
	clear()
	continue_enabled = p_enable_continue
	change_scene(["res://game/globals/scene_main.scn"], context)
	if p_show_credits:
		root.get_current_scene().show_credits()

func focus_out():
	AudioServer.set_fx_global_volume_scale(0)
	AudioServer.set_stream_global_volume_scale(0)
	focus_pause = get_tree().is_paused()
	#if !focus_pause:
	#	set_pause(true)

func focus_in():
	AudioServer.set_stream_global_volume_scale(1)
	AudioServer.set_fx_global_volume_scale(settings.sfx_volume)
	#if !focus_pause:
	#	set_pause(false)

func _notification(what):

	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		focus_out()
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		focus_in()
	elif what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		quit_request()

func quit_request():
	#if root.menu_stack.size() > 0 && (root.menu_stack[root.menu_stack.size()-1] extends preload("res://game/ui/confirmation_popup.gd")):
	#	return
	#var ConfPopup = get_node("/root/main").load_menu("res://game/ui/confirmation_popup.scn")
	#ConfPopup.PopupConfirmation("KEY_QUIT_GAME",self,"","_quit_game")
	pass

func _quit_game():
	get_tree().quit()

func check_achievement(name):
	#printt("********* checking achievement ", name, loading_game)
	if name.find("a/") != 0:
		return

	if loading_game:
		return

	var achiev = name.substr(2, name.length() - 2)
	#if get_global(achiev) == false:
	#	return

	achievements.award(achiev)

func show_rate(url):
	rate_url = url
	var ConfPopup = get_node("/root/main").load_menu("res://game/ui/confirmation_popup.scn")
	ConfPopup.PopupConfirmation("rate2",self,"","_rate_game")
	ConfPopup.set_buttons("rate3", "rate5")

func _rate_game():
	OS.shell_open(rate_url)

func get_hud_scene():
	var hpath = "res://ui/hud.scn"
	return hpath

func _ready():

	save_data = load(Globals.get("application/save_data")).new()
	save_data.start()

	get_tree().set_auto_accept_quit(false)
	randomize()
	add_user_signal("music_volume_changed")
	add_user_signal("paused", ["p_paused"])
	load_settings()

	add_user_signal("global_changed", ["name"])
	add_user_signal("inventory_changed")
	add_user_signal("open_inventory")
	add_user_signal("saved")
	res_cache = preload("res://globals/resource_queue.gd").new()
	printt("calling res cache start")
	res_cache.start()
	compiler = preload("res://globals/esc_compile.gd").new()
	level = preload("res://globals/vm_level.gd").new()
	level.set_vm(self)
	game_size = Vector2()
	game_size.x = Globals.get("display/game_width")
	game_size.y = Globals.get("display/game_height")

	scenes_cache_list.push_back(Globals.get("platform/telon"))
	scenes_cache_list.push_back(get_hud_scene())

	if !Globals.has("debug/skip_cache") || !Globals.get("debug/skip_cache"):
		printt("cache list ", scenes_cache_list)
		for s in scenes_cache_list:
			print("s is ", s)
			res_cache.queue_resource(s, false, true)

	printt("********** vm calling get scene", get_tree(), get_tree().get_root())
	root = get_node("/root/main")

	achievements = preload("res://globals/achievements.gd").new()
	achievements.start()

	connect("global_changed", self, "check_achievement")

	set_process(true)

