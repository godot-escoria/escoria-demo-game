extends Node

"""
This is the script that runs in background, checking for events in the events 
stack and executing them.
Events are managed using 2 structures:
- event_queue: a queue for scheduled events. On each iteration, every event 
	in the queue is updated according time delta. If an event time occurs, it is run 
	(see check_event_queue()).
- levels_stack: stack of events to be run immediately (from an event in ESC file 
	usually)
"""

signal global_changed(global_name)
signal inventory_changed
signal open_inventory
signal saved
signal run_event(ev_name, ev_data)
signal event_done(ev_name)
signal music_volume_changed
signal action_changed
signal paused(p_paused)

onready var resource_cache = load("res://addons/escoria-core/game/core-scripts/resource_queue.gd").new()
onready var save_data = load("res://addons/escoria-core/game/core-scripts/save_data/save_data.gd").new()

# Cached scenes
var scenes_cache_list : Array = []
var scenes_cache : Dictionary = {} # this will eventually have everything in scenes_cache_list forever

# Event currently running
var running_event
# Events queue for timed events
var event_queue : Array = []
# Events stack 
var levels_stack : Array = []

var reserved_globals = [
	"ESC_LAST_SCENE"
]
# Dictionary of global variables
var globals : Dictionary = {}

# Dictionary of active objects
## Active == visible to the player
## Inactive == invisible to the player
var actives : Dictionary = {}
# Dictionary of all objects
## in the form : { "object global_id" : object }
var objects : Dictionary = {}
# Dictionary of all objects' states
## in the form : { "object_name" : "state_name" }
var states : Dictionary = {}
var interactives : Dictionary = {}

# Array containing the event table for each registered object
var objects_events_table : Dictionary

var continue_enabled : bool = true
var loading_game : bool = false
var game

# VERBS & TOOLS 
# to be used like this:
# <current_action> <current_tool> with (target item or hotspot)
# eg: "use" "wrench" (with) (target item or hotspot) 

# Current verb used
var current_action : String = "" setget set_current_action
# Current tool (ESCItem/ESCInventoryItem) used
var current_tool

## If true, we are accepting inputs
#var accept_input : bool
#enum ACCEPTABLE_INPUT {
#	INPUT_NONE
#}

func _ready():
	save_data.start()

	get_tree().set_auto_accept_quit(ProjectSettings.get('escoria/main/force_quit'))
	randomize()
	save_data.load_settings([self, "settings_loaded"])
	
	printt("Calling resource cache start")
	resource_cache.start()

	if !ProjectSettings.get_setting("escoria/platform/skip_cache"):
		scenes_cache_list.push_back(ProjectSettings.get_setting("escoria/main/curtain"))
		scenes_cache_list.push_back(ProjectSettings.get_setting("escoria/main/hud"))

		printt("Cache list ", [scenes_cache_list])
		for s in scenes_cache_list:
			if s != null:
				resource_cache.queue_resource(s, false, true)
	set_process(true)

func _process(delta : float):
	check_event_queue(delta)
	run()
	check_autosave()

# Process the event queue
func check_event_queue(delta : float):
	# Update every event's time in the queue
	for e in event_queue:
		if e.qe_time > 0:
			e.qe_time -= delta

#	if !can_interact() or running_event:
#		return

	var i = event_queue.size()
	while i:
		i -= 1
		var queued_next = event_queue[i]
		print(queued_next)
#		if queued_next.qe_time <= 0:
#			var obj = get_object(queued_next.qe_objname)
#			run_event(obj.event_table[queued_next.qe_event])
#			event_queue.remove(i)
#			break

func is_debug_command(p_event):
	if p_event["ev_name"] != "debug":
		return false
	if p_event["ev_level"].size() != 1:
		return false
	if !(p_event["ev_level"][0].name in escoria.esc_compiler.debug_commands):
		return false
	return true

# Called by run_game()
func run_event(p_event):
	"""
	Run an event
	"""
	if is_debug_command(p_event):
		return run_debug_command(p_event)
	else:
		running_event = p_event
		add_level(p_event, true)

func run_debug_command(p_event):
	return callv(p_event["ev_level"][0].name, p_event["ev_level"][0].params)

func add_level(p_event, p_root : bool):
	"""
	Add an ESCEvent to events stack
	p_event: the ESCEvent
	p_root: bool 
	"""
	levels_stack.push_back(instance_level(p_event, p_root))
	return esctypes.EVENT_LEVEL_STATE.CALL

func instance_level(p_event : esctypes.ESCEvent, p_root : bool):
	var new_level = {
		"ip": 0,								# Current instruction id
		"instructions": p_event.ev_level,		# List of instructions (commands)
		"waiting": false,						# If true, wait for current command to be finished (esc_runner_level.finished())
		"break_stop": p_root,					
		"labels": {},
		"flags": p_event.ev_flags
	}

	for i in range(p_event.ev_level.size()):
		if p_event.ev_level[i].name == "label":
			var lname = p_event.ev_level[i].params[0]
			new_level.labels[lname] = i
	return new_level

func run():
	if levels_stack.size() == 0:
		# Constantly run in _process: we may have an empty levels_stack and no event
		if running_event:
			emit_signal("event_done", running_event.ev_name)
			running_event = null
		return

	while levels_stack.size() > 0:
		var ret = run_top()
		if ret == esctypes.EVENT_LEVEL_STATE.YIELD:
			return
		if ret == esctypes.EVENT_LEVEL_STATE.BREAK:
			while levels_stack.size() > 0 && !(levels_stack[levels_stack.size()-1].break_stop):
				levels_stack.remove(levels_stack.size()-1)
			levels_stack.remove(levels_stack.size()-1)

func run_top():
	var top = levels_stack[levels_stack.size()-1]
#	printt("-----> TOP:", top)
	var ret = $esc_level_runner.resume(top)
	if ret == esctypes.EVENT_LEVEL_STATE.RETURN || ret == esctypes.EVENT_LEVEL_STATE.BREAK:
		levels_stack.remove(levels_stack.size()-1)
	return ret

func test(cmd):
	if "if_true" in cmd.conditions.keys():
		for flag in cmd.conditions.if_true:
			if !get_global(flag):
				return false
	if "if_false" in cmd.conditions.keys():
		for flag in cmd.conditions.if_false:
			if get_global(flag):
				return false
	if "if_inv" in cmd.conditions.keys():
		for flag in cmd.conditions.if_inv:
			if !inventory_has(flag):
				return false
	if "if_not_inv" in cmd.conditions.keys():
		for flag in cmd.conditions.if_not_inv:
			if inventory_has(flag):
				return false
	if "if_active" in cmd.conditions.keys():
		for flag in cmd.conditions.if_active:
			if not flag in actives or not actives[flag]:
				return false
	if "if_not_active" in cmd.conditions.keys():
		for flag in cmd.conditions.if_not_active:
			if flag in actives and actives[flag]:
				return false
	if "if_eq" in cmd.conditions.keys():
		for flag in cmd.conditions.if_eq:
			if !is_global_equal_to(flag[0], flag[1]):
				return false
	if "if_ne" in cmd.conditions.keys():
		for flag in cmd.conditions.if_ne:
			if is_global_equal_to(flag[0], flag[1]):
				return false
	if "if_gt" in cmd.conditions.keys():
		for flag in cmd.conditions.if_gt:
			if !is_global_greater_than(flag[0], flag[1]):
				return false
	if "if_ge" in cmd.conditions.keys():
		for flag in cmd.conditions.if_ge:
			if is_global_less_than(flag[0], flag[1]):
				return false
	if "if_lt" in cmd.conditions.keys():
		for flag in cmd.conditions.if_lt:
			if !is_global_less_than(flag[0], flag[1]):
				return false
	if "if_le" in cmd.conditions.keys():
		for flag in cmd.conditions.if_le:
			if is_global_greater_than(flag[0], flag[1]):
				return false
	return true

func inventory_has(p_obj):
	return get_global("i/"+p_obj)

func items_in_inventory():
	var items = []
	for glob in globals.keys():
		if glob.begins_with("i/") and globals[glob] == "true":
			items.push_back(glob.rsplit("i/", false)[0])
	return items

func get_global(name):
	# If no value or looks like boolean, return boolean for backwards compatibility
	if not name in globals or globals[name].to_lower() == "false":
		return false
	if globals[name].to_lower() == "true":
		return true
	return globals[name]

# Set global state 'name' to 'value' (can be true or false)
# 
func set_global(name, val, force_change_reserved : bool = false):
	if name in reserved_globals and !force_change_reserved:
		escoria.logger.report_warnings("esc_runner.gd:set_global()", 
			["Global " + name + " is reserved. Value not modified."])
		return
	globals[name] = val
	# printt("global changed at global_vm, emitting for ", name, val)
	emit_signal("global_changed", name)

func set_globals(pattern : String, val):
	for key in globals:
		if key.match(pattern):
			set_global(key, val)
#			globals[key] = val
#			emit_signal("global_changed", key)

func dec_global(name, diff):
	var global = get_global(name)
	global = int(global) if global else 0
	set_global(name, str(global - diff))

func inc_global(name, diff):
	var global = get_global(name)
	global = int(global) if global else 0
	set_global(name, str(global + diff))

func is_global_equal_to(name, val):
	var global = get_global(name)
	if global and val and global == val:
		return true

func is_global_greater_than(name, val):
	var global = get_global(name)
	if global and val and int(global) > int(val):
		return true

func is_global_less_than(name, val):
	var global = get_global(name)
	if global and val and int(global) < int(val):
		return true

func jump(p_label):
	while levels_stack.size() > 0:
		var top = levels_stack[levels_stack.size()-1]
		printt("top labels: ", top.labels, p_label)
		if p_label in top.labels:
			top.ip = top.labels[p_label]
			return
		else:
			if top.break_stop || levels_stack.size() == 1:
				escoria.logger.report_errors("esc_runner.gd:jump()", 
					["ESC: Jump to inexisting label: " + p_label])
				levels_stack.remove(levels_stack.size()-1)
				break
			else:
				levels_stack.remove(levels_stack.size()-1)

func check_autosave():
	pass

func set_current_action(action : String):
	if ! action is String:
		escoria.logger.report_errors("esc_runner.gd", 
			["Trying to set_current_action: " + str(typeof(action))])

	if action != current_action:
		clear_current_tool()
		
	current_action = action
	emit_signal("action_changed")

func clear_current_action():
	set_current_action("")

func clear_current_tool():
	current_tool = null

func change_scene(params, context, run_events=true):
	escoria.logger.info("Change scene to " + params[0] + " with run_events " + str(run_events))
#	check_cache()
#	main.clear_scene()
#	camera = null
	event_queue = []
	
	escoria.main.scene_transition.fade_out()
	yield(escoria.main.scene_transition, "transition_done")
	
	# Regular events need to be reset immediately, so we don't
	# accidentally `yield()` on them, for performance reasons.
	# This does not affect `stack` so execution is fine anyway.
	if running_event and running_event.ev_name != "load":
		emit_signal("event_done", running_event.ev_name)
		running_event = null

	var res_room = resource_cache.get_resource(params[0])
	var res_game = resource_cache.get_resource(ProjectSettings.get_setting("escoria/ui/game_scene"))
	if !res_room:
		escoria.logger.report_errors("esc_runner.gd:change_scene()", 
			["Resource not found: " + params[0]])
	if !res_game:
		escoria.logger.report_errors("esc_runner.gd:change_scene()", 
			["Resource not found: " + ProjectSettings.get_setting("escoria/ui/game_scene")])
		
	resource_cache.clear()
	
	# Load game scene
	var game_scene = res_game.instance()
	if !game_scene:
		escoria.logger.report_errors("esc_runner.gd:change_scene()", 
			["Failed loading scene " + ProjectSettings.get_setting("escoria/ui/game_scene")])
	
	# Load room scene
	var room_scene = res_room.instance()
	if room_scene:
		room_scene.add_child(game_scene)
		room_scene.move_child(game_scene, 0)
		var events = escoria.main.set_scene(room_scene, run_events)
		
		escoria.main.scene_transition.fade_in()
		yield(escoria.main.scene_transition, "transition_done")
		
		# If scene was never visited, add "ready" event to the events stack
		if !scenes_cache.has(room_scene.global_id) \
			and "ready" in events:
			run_event(events["ready"])
		
		# :setup is pretty much required in the code, but fortunately
		# we can help out with cases where one isn't necessary otherwise
		if not "setup" in events:
			var fake_setup = escoria.esc_compiler.compile_str(":setup\n")
			events["setup"] = fake_setup["setup"]
		# Finally we add the setup on to of the events stack so that it is ran first
		run_event(events["setup"])
		
		escoria.inputs_manager.hotspot_focused = ""
		if !scenes_cache_list.has(params[0]):
			scenes_cache_list.push_back(params[0])
			scenes_cache[room_scene.global_id] = params[0]
	else:
		escoria.logger.report_errors("esc_runner.gd:change_scene()", 
			["Failed loading scene " + params[0]])

	if context != null:
		context.waiting = false
	
	# Re-apply actives
	for active in actives:
		set_active(active, actives[active])
	
#	cam_target = null
#	autosave_pending = true


func superpose_scene(params, context, run_events=true):
	printt("superposing scene ", params[0], " with run_events ", run_events)
#	check_cache()
#	main.clear_scene()
#	camera = null
#	event_queue = []

	# Regular events need to be reset immediately, so we don't
	# accidentally `yield()` on them, for performance reasons.
	# This does not affect `stack` so execution is fine anyway.
	if running_event and running_event.ev_name != "load":
		emit_signal("event_done", running_event.ev_name)
		running_event = null

	var res_room = resource_cache.get_resource(params[0])
	var res_game = resource_cache.get_resource(ProjectSettings.get_setting("escoria/ui/game_scene"))
	if !res_room:
		escoria.logger.report_errors("esc_runner.gd:superpose_scene()", 
			["Resource not found: " + params[0]])
	if !res_game:
		escoria.logger.report_errors("esc_runner.gd:superpose_scene()", 
			["Resource not found: " + ProjectSettings.get_setting("escoria/ui/game_scene")])
		
	resource_cache.clear()
	
	# Load game scene
	var game_scene = res_game.instance()
	if !game_scene:
		escoria.logger.report_errors("esc_runner.gd:superpose_scene()", 
			["Failed loading scene " + ProjectSettings.get_setting("escoria/ui/game_scene")])
	
	# Load room scene
	var room_scene = res_room.instance()
	if room_scene:
		get_node("/root").add_child(room_scene)
		
		var target = context.get("set_position")
		if target:
			if target is Vector2:
				room_scene.set_position(target)
			if target is String:
				var obj  = get_object(target)
				room_scene.set_position(obj.get_global_position())
		
		escoria.inputs_manager.hotspot_focused = false
		if !scenes_cache_list.has(params[0]):
			scenes_cache_list.push_back(params[0])
			if room_scene.get("global_id"):
				scenes_cache[room_scene.global_id] = params[0]
			else:
				scenes_cache[room_scene.name] = params[0]
	else:
		escoria.logger.report_errors("esc_runner.gd:superpose_scene()", 
			["Failed loading scene " + params[0]])

	if context != null:
		context.waiting = false
	
	# Re-apply actives
	for active in actives:
		set_active(active, actives[active])

#	cam_target = null
#	autosave_pending = true


func run_game(actions : Dictionary):
	set_process(true)
	# `load` and `ready` are exclusive because you probably don't want to
	# reset the game state when a scene becomes ready, and `ready` is
	# redundant when `load`ing state anyway.
	# `start` is used only in your `escoria/platform/game_start_script` .esc 
	# file to start the game.
	if "start" in actions:
		clear()
		run_event(actions["start"])
		escoria.main_menu_instance.hide()
	elif "load" in actions:
		clear()
		run_event(actions["load"])
	elif "ready" in actions:
		run_event(actions["ready"])

func clear():
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "game_cleared")
	levels_stack = []
	globals = {}
	objects = {}
	states = {}
	actives = {}
	interactives = {}
	event_queue = []
	continue_enabled = true
	loading_game = false


func register_object(name : String, val : Object, force : bool = false):
	if !name:
		escoria.logger.report_errors("esc_runner.gd:register_object()", 
			["global_id not given for " + val.get_class() + " " + val.name])

	if name in objects and not force:
		escoria.logger.report_errors("esc_runner.gd:register_object()", 
			["Trying to register already registered object " + name + ": " \
			+ val.get_class() + " (" + val.name + ")"])

	objects[name] = val

	if not val.is_connected("tree_exited", self, "object_exit_scene"):
		val.connect("tree_exited", self, "object_exit_scene", [name])

	# Most objects have states/animations, but don't count on it
#	if val.has_method("set_state"):
	if val is ESCItem or val is ESCPlayer:
		if name in states:
			set_state(name, [states[name], true])
		else:
			set_state(name, [esctypes.OBJ_DEFAULT_STATE])
	
	if val is ESCItem:
		if val.is_interactive:
			set_interactive(name, true)

	if val.get("esc_script") != null and !val.get("esc_script").empty():
		objects_events_table[name] = escoria.esc_compiler.load_esc_file(val.esc_script)
		

func get_object(name):
	if !(name in objects):
		return null
	return objects[name]


# Activates the action for given params
# p_action String Action to execute (defined in attached ESC file and in action verbs UI)
#	- eg: arrived, use, look, pickup...
# p_params Array 
#	- 0 Object Target object
func activate(p_action : String, p_param : Array):
	escoria.logger.info("Action " + p_action + " with params ", [p_param])
#	if p_param[0].global_id:
#		printt("("+p_param[0].global_id+")")
	var what = p_param[0]
	
	# If we're using an action which item requires to combine
	if what is ESCItem and p_action in what.combine_if_action_used_among:
		# Check if object must be in inventory to be used
		if what is ESCItem and what.use_from_inventory_only:
			if !inventory_has(what.global_id):
				# TODO Either use fallback here, or run pickup action before use
				escoria.logger.report_warnings("esc_runner.gd:activate()", 
					["Trying to " + p_action + " on object " + what.global_id 
					+ " but item must be in inventory."])
				return esctypes.EVENT_LEVEL_STATE.YIELD
			else: 
					
				# Player has item in inventory, we check the element to use on
				if p_param.size() > 1:
					var combine_with = p_param[1]
					
					var do_combine = false
					if combine_with is ESCItem and combine_with.use_from_inventory_only:
						if inventory_has(combine_with.global_id):
							do_combine = true
					else:
						do_combine = true
					
					if do_combine:
						if objects_events_table[what.global_id].has(p_action + " " + combine_with.global_id):
							run_event(objects_events_table[what.global_id][p_action + " " + combine_with.global_id])
							return esctypes.EVENT_LEVEL_STATE.RETURN
						elif objects_events_table[combine_with.global_id].has(p_action + " " + what.global_id) \
							and !combine_with.combine_is_one_way:
							run_event(objects_events_table[combine_with.global_id][p_action + " " + what.global_id])
							return esctypes.EVENT_LEVEL_STATE.RETURN
						else:
							var errors = ["Attempted to execute inexisting action " + \
								p_action + " between item " + combine_with.global_id + " and item " + what.global_id]
							if combine_with.get("combine_is_one_way") != null \
								and combine_with.combine_is_one_way:
									errors.append("Reason: " + combine_with.global_id + "'s item interaction is one-way.")
							escoria.logger.report_warnings("esc_runner.gd:activate()", errors)
								
							return esctypes.EVENT_LEVEL_STATE.YIELD
					else:
						# TODO Use fallback here
						pass
						
				else:
					# We're missing a target here. 
					# Tell the Label to add a conjunction and wait for another click
					# to add the target to p_param. Until then, return false.
					current_tool = what
					return esctypes.EVENT_LEVEL_STATE.YIELD
	
	if what.global_id in objects_events_table:
		if p_action in objects_events_table[what.global_id]:
			run_event(objects_events_table[what.global_id][p_action])
		else:
			escoria.logger.report_warnings("esc_runner.gd:activate()", 
				["Action '" + p_action + "' requested on object '" \
				+ what.global_id + "' but action doesn't exist in attached ESC file.",
				"TODO: manage fallbacks."])
			return esctypes.EVENT_LEVEL_STATE.RETURN
	else:
		escoria.logger.report_warnings("esc_runner.gd:activate()", 
				["Action '" + p_action + "' requested on object '" + what.global_id \
				+ "' but object does not exist in objects_events_table.", \
				"Does object " + what.global_id + " have an attached ESC file?"])
		return esctypes.EVENT_LEVEL_STATE.RETURN
	return esctypes.EVENT_LEVEL_STATE.RETURN


func get_state(name : String):
	return states[name]


func get_active(name : String) -> bool:
	if actives.has(name):
		return actives[name]
	return false

"""
Return the interactive object given its global_id.
"""
func get_interactive(global_id : String):
	if interactives.has(global_id):
		return interactives[global_id]
	return false


"""
Change an object state and play its animation (if it has one)
p_params[] :
	- String state : the state name
	- bool immediate (default=false) : if true, the animation is not played and immediately goes to the last frame
"""
func set_state(global_id : String, p_params : Array):
	var obj = get_object(global_id)
	states[global_id] = p_params[0]
	var immediate : bool = false
	if p_params.size() > 1:
		immediate = p_params[1]
	
	# A Hotspot can have a child item, if this item has an empty sprite
	# (the hotspot is there to get the user input)
	var animation_node
	if obj is ESCItem:
		#if obj.get("animation") != null:
		#	animation_node = obj.get("animation")
		if obj.get_animation_player() != null:
			animation_node = obj.get_animation_player()
	
	if animation_node:
		animation_node.stop()
		var actual_animator
		if animation_node is AnimationPlayer:
			actual_animator = animation_node
		elif animation_node is AnimatedSprite:
			actual_animator = animation_node.frames
			
		if actual_animator.has_animation(p_params[0]):
			if !immediate:
				animation_node.play(p_params[0])
			else:
				# The animation is not played, we directly set it at its last frame
				if animation_node is AnimatedSprite:
					animation_node.animation = p_params[0]
				else:
					animation_node.current_animation = p_params[0]
					var animation = actual_animator.get_animation(p_params[0])
					var animation_length = animation.length
					animation_node.seek(animation_length)
	escoria.logger.info("Item " + obj.global_id + " changed state to: " + p_params[0])

"""
When object is active, it is VISIBLE.
When object is inactive, it is HIDDEN.
"""
func set_active(name : String, active):
	actives[name] = active
	if objects.has(name) and is_instance_valid(objects[name]):
		if objects[name] is ESCInventoryItem:
			return
		
		if active:
			objects[name].show()
		else:
			objects[name].hide()

"""
When object is interactive, it can be focused
When object is not interactive, it cannot be focused and used
"""
func set_interactive(name : String, active):
	interactives[name] = active



"""
Callback called by ESCItems when it emits "tree_exit", ie. removed from scene.
Item is kept in objects[] array if it is in inventory.
"""
func object_exit_scene(name : String):
	# If object is in inventory, save it before it's destroyed so we still have
	# its data in objects[]
	if inventory_has(name):
		objects[name] = objects[name].duplicate()
	else:
		if name != "bg_music":
			escoria.logger.info("Object " + name + " removed from scene.")
			objects.erase(name)


func check_obj(name, cmd):
	var obj = escoria.esc_runner.get_object(name)
	if obj == null:
		escoria.logger.report_errors("", ["Global id "+name+" not found for " + cmd])
		return false
	return true

