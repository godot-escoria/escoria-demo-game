extends Node

var running_event

var stack = []
var globals = {}
var objects = {}
var customs = []

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

var game

var res_cache

var cam_target = null
var cam_speed = 0
var camera
var camera_limits

## One game, one VM; there are many things we can have only one of, track them here.
var action_menu = null	   # If the game uses an action menu, register it here
var tooltip = null         # The tooltip scene, registered by game.gd
var hover_object = null    # Best-effort attempt to track what's under the mouse
var overlapped_obj = null  # Would be covered by eg. a collapsible inventory ("cache" tooltip)

var current_action = ""    # Verb or action menu button
var current_tool = null    # Item chosen from inventory

var last_autosave = 0
var autosave_pending = false
const AUTOSAVE_TIME_MS = 64 * 1000
const DOUBLECLICK_TIMEOUT = 0.2  # seconds

var save_data

var continue_enabled = true

var focus_pause = false

var loading_game = false
var achievements = null
var rate_url = ""

# These are settings that the player can affect and save/load later
var settings_default = {
	"text_lang": ProjectSettings.get_setting("escoria/application/text_lang"),
	"voice_lang": ProjectSettings.get_setting("escoria/application/voice_lang"),
	"speech_enabled": ProjectSettings.get_setting("escoria/application/speech_enabled"),
	"music_volume": 1,
	"sfx_volume": 1,
	"voice_volume": 1,
	"fullscreen": false,
	"skip_dialog": true,
	"rate_shown": false,  # XXX: What is this? `achievements.gd` looks like iOS-only
}


var scenes_cache_list = preload("res://globals/scenes_cache.gd").scenes

var scenes_cache = {} # this will eventually have everything in scenes_cache_list forever

var settings

var zoom_time
var zoom_target
var zoom_step

# This is needed to adjust dialog positions and such
var zoom_transform

# Helpers to deal with player's and items' angles
func _get_deg_from_rad(rad_angle):
	# We need some special magic to rotate the node
	var deg = rad2deg(rad_angle) + 180 + 45
	if deg >= 360:
		deg = deg - 360

	return deg

func _get_dir(angle, obj_name, animations):
	var deg = _get_deg_from_rad(angle)
	return _get_dir_deg(deg, obj_name, animations)

func _get_dir_deg(deg, obj_name, animations):
	var dir = -1
	var i = 0
	for ang in animations.dir_angles:
		if deg <= ang:
			dir = i
			break
		i+=2

	# It's an error to have the animations misconfigured
	if dir == -1:
		vm.report_errors("obj_name", ["No direction found for " + str(deg)])
	return dir


func save_settings():
	save_data.save_settings(settings, null)

func load_settings():
	save_data.load_settings([self, "settings_loaded"])

func settings_loaded(p_settings):
	printt("******* settings loaded", p_settings)
	if p_settings != null:
		settings = p_settings
	else:
		settings = {}

	for k in settings_default:
		if !(k in settings):
			settings[k] = settings_default[k]

	# TODO Apply globally
#	AudioServer.set_fx_global_volume_scale(settings.sfx_volume)
	AudioServer.set_bus_volume_db(0, settings.sfx_volume)
	TranslationServer.set_locale(settings.text_lang)
	music_volume_changed()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "ui", "language_changed")

func music_volume_changed():
	emit_signal("music_volume_changed")

func hover_begin(obj):
	assert obj is esc_type.ITEM or obj is esc_type.TRIGGER

	hover_object = obj

func hover_end():
	assert hover_object

	# Without this, it's possible the event remains perpetually clicked
	# when doing a drag-and-drop motion. Then the player will never move.
	if "clicked" in hover_object:
		hover_object.clicked = false

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
				pos += obj.get_position()
		if count > 0:
			pos = pos / count
	else:
		pos = target.get_position()

	var cpos = camera.get_position()

	# The camera position is set to target when it's about to overstep it,
	# or when it's moved there instantly.
	# Compare the camera and target position until then
	if cpos != pos:
		var v = pos - cpos  # vector to move along
		var step = cam_speed * time  # pixel size of step to move

		# This is where we may overstep or move instantly
		if step > v.length() || cam_speed == 0:
			camera.set_position(pos)
		else:
			pos = cpos + v.normalized() * step
			camera.set_position(pos)

	if zoom_target:
		var zstep = zoom_step * time
		var diff = camera.zoom - zoom_target
		if zstep.length() > diff.length() || zoom_time == 0:
			camera.zoom = zoom_target
			zoom_target = null
			zoom_transform = camera.get_canvas_transform()
		else:
			camera.zoom += zstep
	# Even when not zooming, somehow the clamping of dialog, when the
	# scene is not zoomed, goes awry without this :/
	else:
		zoom_transform = camera.get_canvas_transform()

func set_cam_limits(limits):
	camera_limits = limits

func camera_set_target(speed, p_target):
	cam_speed = speed
	cam_target = p_target

func camera_set_zoom(zoom_level, time):
	if zoom_level <= 0.0:
		report_errors("global_vm", ["Tried to set negative or zero zoom level"])
	zoom_time = time
	zoom_target = Vector2(1, 1) * zoom_level
	# Calculate magnitude to zoom per second
	zoom_step = (zoom_target - camera.zoom) / time

func inventory_has(p_obj):
	return get_global("i/"+p_obj)

func inventory_set(p_obj, p_has):
	set_global("i/"+p_obj, p_has)

func say(params, level):
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "dialog", "say", params, level)

func set_hud_visible(p_visible):
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_visible", p_visible)

func set_tooltip_visible(p_visible):
	# Wrapper that vm_level can use
	if tooltip:
		if p_visible:
			tooltip.show()
		else:
			tooltip.hide()

func dialog_config(params):
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "dialog", "config", params)

func wait(params, level):
	var time = float(params[0])
	printt("wait time ", params[0], time)
	if time <= 0:
		return state_return
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "wait", time, level)
	level.waiting = true
	return state_yield

func is_equal_to(name, val):
	var global = get_global(name)
	if global and val and global == val:
		return true

func is_greater_than(name, val):
	var global = get_global(name)
	if global and val and int(global) > int(val):
		return true

func is_less_than(name, val):
	var global = get_global(name)
	if global and val and int(global) < int(val):
		return true

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
	if "if_active" in cmd:
		for flag in cmd.if_active:
			if not flag in actives or not actives[flag]:
				return false
	if "if_not_active" in cmd:
		for flag in cmd.if_not_active:
			if flag in actives and actives[flag]:
				return false
	if "if_eq" in cmd:
		for flag in cmd.if_eq:
			if !is_equal_to(flag[0], flag[1]):
				return false
	if "if_ne" in cmd:
		for flag in cmd.if_ne:
			if is_equal_to(flag[0], flag[1]):
				return false
	if "if_gt" in cmd:
		for flag in cmd.if_gt:
			if !is_greater_than(flag[0], flag[1]):
				return false
	if "if_ge" in cmd:
		for flag in cmd.if_ge:
			if is_less_than(flag[0], flag[1]):
				return false
	if "if_lt" in cmd:
		for flag in cmd.if_lt:
			if !is_less_than(flag[0], flag[1]):
				return false
	if "if_le" in cmd:
		for flag in cmd.if_le:
			if is_greater_than(flag[0], flag[1]):
				return false

	return true

func dialog(params, level):
	set_hud_visible(false)

	# Ensure tooltip is hidden. It may remain visible when the NPC finishes saying something
	# and then `dialog` is called.
	if tooltip:
		tooltip.hide()
	get_tree().call_group("dialog_dialog", "start", params, level)

func end_dialog(params):
	if not running_event or not "NO_HUD" in running_event.ev_flags:
		vm.set_hud_visible(true)


func instance_level(p_event, p_root):
	var level = {
		"ip": 0,
		"instructions": p_event.ev_level,
		"waiting": false,
		"break_stop": p_root,
		"labels": {},
		"flags": p_event.ev_flags
	}

	for i in range(p_event.ev_level.size()):
		if p_event.ev_level[i].name == "label":
			var lname = p_event.ev_level[i].params[0]
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

func report_warnings(p_path, warnings):
	var text = "Warnings in file "+p_path+"\n\n"
	for e in warnings:
		text += e+"\n"

	print("warning is ", text)

func report_errors(p_path, errors):
	var text = "Errors in file "+p_path+"\n\n"
	for e in errors:
		text += e+"\n"

	print("error is ", text)

	# The only way to - optionally - make errors matter
	if ProjectSettings.get_setting("escoria/platform/terminate_on_errors"):
		assert(false)

func add_level(p_event, p_root):
	stack.push_back(instance_level(p_event, p_root))

	return state_call

func _find_say(level):
	# Recursive helper to see if we have the `say` command,
	# so we can auto-hide a tooltip that follows the mouse
	for command in level:
		if command.name == "say":
			return true
		elif command.name == "branch":
			return _find_say(command.params)

	return false

func run_event(p_event):
	printt("run_event: ", p_event.ev_name, p_event.ev_flags)
	# When the tooltip follows the mouse, you must use `NO_TT` to hide it
	# during dialog or it looks bad. It's easy to miss, so let's automate!
	if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse") and not "NO_TT" in p_event.ev_flags:
		var need_no_tt = _find_say(p_event.ev_level)
		if need_no_tt:
			p_event.ev_flags.push_back("NO_TT")

	running_event = p_event
	if p_event.ev_name == "setup":
		if "CUT_BLACK" in p_event.ev_flags:
			main.telon.cut_to_black()

		add_level(p_event, true)
	else:
		main.set_input_catch(true)

		if "NO_TT" in p_event.ev_flags:
			if tooltip:
				tooltip.hide()

		if "NO_HUD" in p_event.ev_flags:
			set_hud_visible(false)

		add_level(p_event, true)

func sched_event(time, obj, event):
	event_queue.push_back([time, obj, event])

func event_done(ev_name):
	assert ev_name == running_event.ev_name
	printt("event_done: ", running_event.ev_name, running_event.ev_flags)
	if ev_name == "setup":
		if not "LEAVE_BLACK" in running_event.ev_flags:
			main.telon.cut_to_scene()
	else:
		if "NO_TT" in running_event.ev_flags:
			# Let an `overlapped_obj` deal with the tooltip if required
			reset_overlapped_obj()

		if "NO_HUD" in running_event.ev_flags:
			# Do not restore hud if next event is also NO_HUD
			# because that would cause the hud to flash between the events
			if event_queue.size():
				# Timing can be -0.0019 or whatever, so just `int()` it to see if it's immediate
				var time = int(event_queue[-1][0])
				if time == 0:
					var obj = get_object(event_queue[-1][1])
					var next_ev_name = event_queue[-1][2]
					var next_event = obj.event_table[next_ev_name]
					if not "NO_HUD" in next_event.ev_flags:
						set_hud_visible(true)
			else:
				set_hud_visible(true)

	running_event = null

func get_global(name):
	# If no value or looks like boolean, return boolean for backwards compatibility
	if not name in globals or globals[name].to_lower() == "false":
		return false
	if globals[name].to_lower() == "true":
		return true
	return globals[name]

func set_global(name, val):
	globals[name] = val
	# printt("global changed at global_vm, emitting for ", name, val)
	emit_signal("global_changed", name)

func dec_global(name, diff):
	var global = get_global(name)
	global = int(global) if global else 0
	set_global(name, str(global - diff))

func inc_global(name, diff):
	var global = get_global(name)
	global = int(global) if global else 0
	set_global(name, str(global + diff))

func set_globals(pat, val):
	for key in globals:
		if key.match(pat):
			globals[key] = val
			emit_signal("global_changed", key)

func get_global_list():
	return ProjectSettings.keys()

func register_tooltip(p_tooltip):
	if tooltip and p_tooltip != tooltip:
		assert p_tooltip is esc_type.TOOLTIP
	elif not tooltip:
		assert p_tooltip is esc_type.TOOLTIP

	tooltip = p_tooltip

func register_action_menu(p_action_menu):
	if action_menu and p_action_menu != action_menu:
		assert p_action_menu is esc_type.ACTION_MENU
	elif not action_menu:
		assert p_action_menu is esc_type.ACTION_MENU

	action_menu = p_action_menu

func get_object(name):
	if !(name in objects):
		return null
	return objects[name]

func register_object(name, val):
	if !name:
		report_errors("register_object", ["global_id not given for " + val.get_class() + " " + val.name])

	if name in objects:
		report_errors("register_object", ["Trying to register already registered object " + name + ": " + val.get_class() + " (" + val.name + ")"])

	objects[name] = val
	val.connect("tree_exited", self, "object_exit_scene", [name])

	# Most objects have states/animations, but don't count on it
	if val.has_method("set_state"):
		if name in states:
			val.set_state(states[name])
		else:
			val.set_state("default")

	if val.has_method("set_active"):
		if name in actives:
			val.set_active(actives[name])

func get_registered_objects():
	return objects

func save_custom(params):
	# Store `custom obj func_name foo bar` style custom data into savegames
	# by passing in the params as your `custom` node's function takes them
	var param_str = ""
	for param in params:
		param_str += (param + " ")

	customs.push_back("custom " + param_str)

func set_state(name, state):
	states[name] = state

func set_active(name, active):
	actives[name] = active

func set_use_action_menu(obj, should_use_action_menu):
	if obj is esc_type.ITEM:
		obj.use_action_menu = should_use_action_menu

func set_speed(obj, speed):
	if obj is esc_type.INTERACTIVE:
		obj.speed = speed

func set_current_action(p_action):
	assert typeof(p_action) == TYPE_STRING

	if p_action != current_action:
		clear_current_tool()

	current_action = p_action

func clear_current_action():
	set_current_action("")

func clear_action():
	vm.clear_current_tool()

	# It is logical for action menus' actions to be cleared, but verb menus to persist
	if action_menu:
		vm.clear_current_action()

func set_current_tool(p_tool):
	if p_tool:
		assert p_tool is esc_type.ITEM
		assert p_tool.inventory

	current_tool = p_tool

func clear_current_tool():
	current_tool = null

func set_overlapped_obj(obj):
	assert obj is esc_type.ITEM or obj is esc_type.TRIGGER
	if obj is esc_type.ITEM:
		assert not obj.inventory

	overlapped_obj = obj

func reset_overlapped_obj():
	if overlapped_obj:
		if overlapped_obj is esc_type.ITEM:
			assert not overlapped_obj.inventory
			overlapped_obj.emit_signal("mouse_enter_item", overlapped_obj)
		elif overlapped_obj is esc_type.TRIGGER:
			overlapped_obj.emit_signal("mouse_enter_trigger", overlapped_obj)

func clear_overlapped_obj():
	overlapped_obj = null

func object_exit_scene(name):
	objects.erase(name)

func check_event_queue(time):
	for e in event_queue:
		if e[0] > 0:
			e[0] -= time

	if !can_interact() or running_event:
		return

	var i = event_queue.size()
	while i:
		i -= 1
		if event_queue[i][0] <= 0:
			var obj = get_object(event_queue[i][1])
			var ev_name = event_queue[i][2]
			run_event(obj.event_table[ev_name])
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
		# Constantly run in _process: we may have an empty stack and no event
		if running_event:
			emit_signal("event_done", running_event.ev_name)
		return
	while stack.size() > 0:
		var ret = run_top()
		if ret == state_yield:
			return
		if ret == state_break:
			while stack.size() > 0 && !(stack[stack.size()-1].break_stop):
				stack.remove(stack.size()-1)
			stack.remove(stack.size()-1)
	main.set_input_catch(false)
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

func change_scene(params, context, run_events=true):
	# It might be tempting to use `get_tree().change_scene(params[0])`,
	# but this custom solution is safer around your scene structure
	printt("change scene to ", params[0], " with run_events ", run_events)
	#var res = ResourceLoader.load(params[0])
	check_cache()
	main.clear_scene()
	camera = null
	event_queue = []
	var res = res_cache.get_resource(params[0])
	res_cache.clear()
	var scene = res.instance()
	if scene:
		main.set_scene(scene, run_events)
	else:
		report_errors("", ["Failed loading scene "+params[0]+" for change_scene"])

	if context != null:
		context.waiting = false

	camera_set_target(0, null)
	autosave_pending = true

func spawn(params):
	var res = ResourceLoader.load(params[0])
	var scene = res.instance()
	if scene:
		main.get_tree().add_child(scene)
	else:
		report_errors("", ["Failed loading scene "+params[0]+" for spawn"])
		return state_return
	if params.size() > 1:
		var obj = get_object(params[1])
		if obj:
			scene.set_position(obj.get_global_position());
		else:
			report_errors("", ["Global id "+params[1]+" not found for spawn"])
	return state_return

func request_autosave():
	autosave_pending = true


func set_pause(p_pause):
	get_tree().set_pause(p_pause)
	emit_signal("paused", p_pause)

func is_game_active():
	return main.get_current_scene() != null && (main.get_current_scene() is esc_type.SCENE)

func check_autosave():
	if get_global("save_disabled") or not is_game_active():
		return

	var time = OS.get_ticks_msec()
	if autosave_pending || (time - last_autosave) > AUTOSAVE_TIME_MS:
		if running_event:
			if running_event.ev_name == "setup":
				return
			elif running_event.ev_name == "load":
				return

		autosave_pending = true
		var data = save()
		if typeof(data) == TYPE_BOOL && data == false:
			return
		autosave_pending = false
		save_data.autosave(data, [self, "autosave_done"])

func autosave_done(err):
	if err != OK:
		return
	last_autosave = OS.get_ticks_msec()

func check_cache():
	# Warm the cache from the hard-coded list, unless configured to skip
	if ProjectSettings.get_setting("escoria/platform/skip_cache"):
		return

	for s in scenes_cache_list:
		if s in scenes_cache:
			continue
		scenes_cache[s] = res_cache.get_resource(s)

func load_file(p_game):
	var f = File.new()
	if !f.file_exists(p_game):
		return

	game = compile(p_game)

func run_game():
	# `load` and `ready` are exclusive because you probably don't want to
	# reset the game state when a scene becomes ready, and `ready` is
	# redundant when `load`ing state anyway.
	# `start` is used only in your `game.esc` file to start the game.
	if "load" in game:
		clear()
		loading_game = true
		run_event(game["load"])
		main.menu_collapse()
	elif "start" in game:
		clear()
		run_event(game["start"])
		main.menu_collapse()
	elif "ready" in game:
		run_event(game["ready"])

func load_slot(p_game):
	var cb = [self, "game_str_loaded"]
	save_data.load_slot(p_game, cb)

func load_autosave():
	printt("calling load autosave")
	save_data.load_autosave([self, "game_str_loaded"])

func game_str_loaded(p_data = null):
	if p_data == null:
		return

	game = compile_str(p_data)
	clear()
	loading_game = true
	run_event(game["load"])
	main.menu_collapse()

func save():
	if stack.size() != 0:
		return false

	var ret = []

	ret.append(":load\n\n")

	ret.append("cut_scene telon fade_out\n\n")

	# Change the scene up-front so objects and states can be loaded properly,
	# and with events disabled to not confuse the game
	ret.append("change_scene " + main.get_current_scene().get_filename() + " false\n\n")

	ret.append("## Global flags\n\n")
	for k in globals.keys():
		if !globals[k]:
			continue
		ret.append("set_global %s \"%s\"\n" % [k, globals[k]])
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
	for k in objects:
		if k == "player" || objects[k] == null:
			continue

		if "moved" in objects[k] and objects[k].moved:
			var pos = objects[k].get_position()
			ret.append("teleport_pos " + k + " " + str(int(pos.x)) + " " + str(int(pos.y)) + "\n")
			if objects[k].last_deg != null:
				if objects[k].last_deg < 0 or objects[k].last_deg > 360:
					vm.report_errors("global_vm", ["Trying to save game with " + objects[k].name + " at invalid angle " + str(objects[k].last_deg)])
				ret.append("set_angle " + k + " " + str(objects[k].last_deg) + "\n")

	ret.append("\n")
	ret.append("## Player\n\n")

	if main.get_current_scene().has_node("player"):
		var player = main.get_current_scene().get_node("player")
		var pos = player.get_global_position()
		var angle = player.last_deg
		ret.append("teleport_pos player " + str(pos.x) + " " + str(pos.y) + "\n")
		# Angle may be unset if saving occurs when entering another room
		if angle:
			if angle < 0 or angle > 360:
				vm.report_errors("global_vm", ["Trying to save game with player at invalid angle " + str(angle)])
			ret.append("set_angle player " + str(angle) + "\n")

	ret.append("\n")
	ret.append("## Camera\n\n")
	if cam_target != null:
		if typeof(cam_target) == typeof(Vector2()):
			#ret.append("camera_set_position " + str(cam_speed) + " " + str(int(cam_target.x)) + " " + str(int(cam_target.y)) + "\n")
			ret.append("camera_set_position 0 " + str(int(cam_target.x)) + " " + str(int(cam_target.y)) + "\n")
		else:
			var tlist = ""

			if typeof(cam_target) == typeof([]):
				for t in cam_target:
					tlist = tlist + " " + t
			else:
				tlist = tlist + " " + cam_target


			ret.append("camera_set_target 0" + tlist + "\n")
			ret.append("camera_set_target " + str(cam_speed) + tlist + "\n")

	if customs:
		ret.append("\n")
		ret.append("## Custom\n\n")

		for custom in customs:
			ret.append(custom + "\n")

		ret.append("\n")

	# Always save the zoom, but assume symmetrical zoom because esc scripts don't support anything else
	ret.append("camera_set_zoom " + str(camera.zoom.x) + "\n")

	for e in event_queue:
		ret.append("sched_event " + str(e[0]) + " " + str(e[1]) + " " + str(e[2]) + "\n")

	ret.append("\ncut_scene telon fade_in\n")

	emit_signal("saved")

	return ret

func set_camera(p_cam):
	camera = p_cam
	zoom_transform = camera.get_canvas_transform()

func clear():
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "game_cleared")
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
	change_scene(["res://globals/scene_main.tscn"], context)
	if p_show_credits:
		var end = true  # game over, show separate end credits if available
		main.get_current_scene().show_credits(end)

func focus_out():
	#AudioServer.set_fx_global_volume_scale(0)
	AudioServer.set_bus_volume_db(0, 0)
	#AudioServer.set_stream_global_volume_scale(0)
	focus_pause = get_tree().is_paused()
	#if !focus_pause:
	#	set_pause(true)

func focus_in():
	#AudioServer.set_stream_global_volume_scale(1)
	AudioServer.set_bus_volume_db(0, 1)
	#AudioServer.set_fx_global_volume_scale(settings.sfx_volume)
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
	#if main.menu_stack.size() > 0 && (main.menu_stack[main.menu_stack.size()-1] is preload("res://demo/ui/confirmation_popup.gd")):
	#	return
	#var ConfPopup = main.load_menu("res://demo/ui/confirmation_popup.tscn")
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
	var ConfPopup = main.load_menu("res://demo/ui/confirmation_popup.tscn")
	ConfPopup.PopupConfirmation("rate2",self,"","_rate_game")
	ConfPopup.set_buttons("rate3", "rate5")

func _rate_game():
	OS.shell_open(rate_url)

func get_hud_scene():
	var hpath = ProjectSettings.get_setting("escoria/ui/hud")
	return hpath

func _ready():
	save_data = load(ProjectSettings.get_setting("escoria/application/save_data")).new()
	save_data.start()

	get_tree().set_auto_accept_quit(ProjectSettings.get('escoria/platform/force_quit'))
	randomize()
	add_user_signal("music_volume_changed")
	add_user_signal("paused", ["p_paused"])
	load_settings()

	add_user_signal("global_changed", ["name"])
	add_user_signal("inventory_changed")
	add_user_signal("open_inventory")
	add_user_signal("saved")
	add_user_signal("run_event", ["ev_name", "ev_data"])
	add_user_signal("event_done", ["ev_name"])

	res_cache = preload("res://globals/resource_queue.gd").new()
	printt("calling res cache start")
	res_cache.start()
	compiler = preload("res://globals/esc_compile.gd").new()
	level = preload("res://globals/vm_level.gd").new()
	level.set_vm(self)
	game_size = get_viewport().size

	if !ProjectSettings.get_setting("escoria/platform/skip_cache"):
		scenes_cache_list.push_back(ProjectSettings.get_setting("escoria/platform/telon"))
		scenes_cache_list.push_back(get_hud_scene())

		printt("cache list ", scenes_cache_list)
		for s in scenes_cache_list:
			print("s is ", s)
			res_cache.queue_resource(s, false, true)

	printt("********** vm calling get scene", get_tree(), get_node("/root"))

	achievements = preload("res://globals/achievements.gd").new()
	achievements.start()

	connect("global_changed", self, "check_achievement")
	connect("run_event", self, "run_event")
	connect("event_done", self, "event_done")

	set_process(true)

