extends Node

# This script runs the ESCCommands contained in the ESCEvent.

var current_context
onready var esc_runner = get_parent()

func _ready():
	pass

func finished(context = null):
	if context != null:
		context.waiting = false
	else:
		current_context.waiting = false


func check_obj(name, cmd):
	var obj = escoria.esc_runner.get_object(name)
	if obj == null:
		escoria.report_errors("", ["Global id "+name+" not found for " + cmd])
		return false
	return true

func resume(context):
	current_context = context
	if context.waiting:
		return esctypes.EVENT_LEVEL_STATE.YIELD
	var count = context.instructions.size()
	while context.ip < count:
		var top = esc_runner.levels_stack.size()
		var ret = run(context)
		context.ip += 1
		if top < esc_runner.levels_stack.size():
			return esctypes.EVENT_LEVEL_STATE.CALL
		if ret == esctypes.EVENT_LEVEL_STATE.YIELD:
			return esctypes.EVENT_LEVEL_STATE.YIELD
		if ret == esctypes.EVENT_LEVEL_STATE.CALL:
			return esctypes.EVENT_LEVEL_STATE.CALL
		if ret == esctypes.EVENT_LEVEL_STATE.BREAK:
			if context.break_stop:
				break
			else:
				return esctypes.EVENT_LEVEL_STATE.BREAK
		if ret == esctypes.EVENT_LEVEL_STATE.REPEAT:
			context.ip = 0
		if ret == esctypes.EVENT_LEVEL_STATE.JUMP:
			return esctypes.EVENT_LEVEL_STATE.JUMP
	context.ip = 0
	return esctypes.EVENT_LEVEL_STATE.RETURN

func run(context):
	var cmd = context.instructions[context.ip]
	if cmd.name == "label":
		return esctypes.EVENT_LEVEL_STATE.RETURN
	if !esc_runner.test(cmd):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	#print("name is ", cmd.name)
	#if !(cmd.name in self):
	#	esc_runner.report_errors("", ["Unexisting command "+cmd.name])
	return call(cmd.name, cmd.params)


"""
Automatically called when a dialog line is said.
"""
func dialog_line_finished() -> void:
#	escoria.esc_runner.get_node("esc_level_runner").finished()
	finished()
	escoria.dialog_player.is_speaking = false
	escoria.current_state = escoria.GAME_STATE.DEFAULT

"""
"""
func accept_input():
	pass


"""
"""
func autosave():
	pass


"""
"""
func anim():
	pass


"""
"""
func branch(command_params : Array):
	var branch_ev = esctypes.ESCEvent.new("branch", command_params, [])
	return escoria.esc_runner.add_level(branch_ev, false)


"""
"""
func camera_push():
	pass


"""
"""
func camera_set_drag_margin_enabled():
	pass


"""
"""
func camera_set_pos():
	pass


"""
"""
func camera_set_target():
	pass


"""
"""
func camera_set_zoom():
	pass


"""
"""
func camera_set_zoom_height():
	pass


"""
"""
func camera_shift():
	pass

"""
"""
func change_scene(params):
	# Savegames must have events disabled, so saving the game adds a false to params
	var run_events = true
	if params.size() == 2:
		run_events = bool(params[1])
	
	# looking for localized string format in scene. this should be somewhere else
	var sep = params[0].find(":\"")
	if sep >= 0:
		var path = params[0].substr(sep + 2, params[0].length() - (sep + 2))
		escoria.esc_runner.call_deferred("change_scene", [path], current_context, run_events)
	else:
		escoria.esc_runner.call_deferred("change_scene", params, current_context, run_events)
	
	current_context.waiting = true
	return esctypes.EVENT_LEVEL_STATE.YIELD

"""
"""
func custom():
	pass


"""
"""
func cut_scene():
	pass


"""
"""
func debug():
	pass


"""
"""
func dec_global():
	pass


"""
"""
func inc_global():
	pass


"""
"""
func dialog(command_params : Array):
	current_context.waiting = true
	current_context.in_dialog = true
	escoria.current_state = escoria.GAME_STATE.DIALOG
	if !escoria.dialog_player:
		escoria.dialog_player = escoria.main.current_scene.get_node("game/ui/dialog_layer/dialog_player")
	var options = command_params.slice(1, command_params.size())
	escoria.dialog_player.start_dialog_choices(command_params[0], options)
	return esctypes.EVENT_LEVEL_STATE.YIELD


"""
"""
func dialog_config():
	pass


"""
Enable the ESCTerrain's NavigationPolygonInstance defined by given node name. 
Disables previously activated NavigationPolygonInstance.
"""
func enable_terrain(command_params : Array):
	var name : String = command_params[0]
	if escoria.room_terrain.has_node(name):
		var new_active_navigation_instance = escoria.room_terrain.get_node(name)
		escoria.room_terrain.current_active_navigation_instance.enabled = false
		escoria.room_terrain.current_active_navigation_instance = new_active_navigation_instance
		escoria.room_terrain.current_active_navigation_instance.enabled = true

"""
"""
func game_over(command_params : Array):
	pass


"""
"""
func inventory_add(command_params : Array):
	pass


"""
"""
func inventory_remove(command_params : Array):
	pass


"""
"""
func inventory_open(command_params : Array):
	pass


"""
"""
func jump(command_params : Array):
	pass


"""
"""
func play_snd(command_params : Array):
	pass


"""
"""
func queue_animation(command_params : Array):
	pass


"""
"""
func queue_resource(command_params : Array):
	pass


"""
"""
func repeat(command_params : Array):
	pass


"""
Make a character say one line.
Usage: say object_id line [dialog_ui_name]
"""
func say(command_params : Array) -> esctypes:
	current_context.waiting = true
	
	var dict : Dictionary
	var dialog_scene_name = ProjectSettings.get_setting("escoria/ui/default_dialog_scene")
	
	if dialog_scene_name.empty():
		escoria.report_errors("level_esc_runners.gd:say()", ["Project setting 'escoria/ui/default_dialog_scene' is not set. Please set a default dialog scene."])
	var file = dialog_scene_name.get_file()
	var extension = dialog_scene_name.get_extension()
	dialog_scene_name = file.rstrip("." + extension)
	
	# Manage specific dialog scene
	if command_params.size() > 2:
		dialog_scene_name = command_params[2]
		
	dict = {
		"line": command_params[1],
		"ui": dialog_scene_name
		#"ui": "dialog_label"
		#"ui": "dialog_box_inset"
	}
	escoria.current_state = escoria.GAME_STATE.DIALOG
	if !escoria.dialog_player:
		escoria.dialog_player = escoria.main.current_scene.get_node("game/ui/dialog_layer/dialog_player")
	escoria.dialog_player.say(command_params[0], dict)
	return esctypes.EVENT_LEVEL_STATE.YIELD


"""
Sets object as active or inactive. Active objects are displayed in scene and respond
to inputs. Inactives are hidden.
"""
func set_active(command_params : Array):
	if !check_obj(command_params[0], "set_active"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	var name : String = command_params[0]
	var value = command_params[1]
	escoria.esc_runner.set_active(name, value)

"""
Set the angle of an object. 
Usage: set_angle object_id angle_degrees
"""
func set_angle(params : Array):
	if !check_obj(params[0], "set_angle"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	var obj = escoria.esc_runner.get_object(params[0])
	obj.set_angle(int(params[1]))
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
"""
func set_state(command_params : Array):
	var global_id : String = command_params[0]
	var p_params : Array = command_params.slice(1, command_params.size())
	escoria.esc_runner.set_state(global_id, p_params)


"""
"""
func set_hud_visible(command_params : Array):
	pass


"""
"""
func sched_event(command_params : Array):
	pass


"""
"""
func set_global(command_params : Array):
	var name : String = command_params[0]
	var value = command_params[1]
	escoria.esc_runner.set_global(name, value)


"""
"""
func set_globals(command_params : Array):
	pass


"""
"""
func set_interactive(command_params : Array):
	var name : String = command_params[0]
	var value = command_params[1]
	escoria.esc_runner.set_interactive(name, value)


"""
"""
func set_speed(command_params : Array):
	pass


"""
"""
func slide(command_params : Array):
	pass


"""
"""
func slide_block(command_params : Array):
	pass


"""
"""
func spawn(command_params : Array):
	pass


"""
"""
func stop(command_params : Array):
	return esctypes.EVENT_LEVEL_STATE.BREAK

"""
Teleports obj1 at obj2's position. If angle_degrees is set (int), sets obj1's 
angle to angle_degrees.
Usage: teleport obj1 obj2 [angle_degrees]
"""
func teleport(params):
	if !check_obj(params[0], "teleport"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	if !check_obj(params[1], "teleport"):
		return esctypes.EVENT_LEVEL_STATE.RETURN

	var angle
	if params.size() > 2:
		angle = int(params[2])

	escoria.esc_runner.get_object(params[0]).teleport(escoria.esc_runner.get_object(params[1]), angle)
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
"""
func teleport_pos(command_params : Array):
	pass


"""
"""
func turn_to(command_params : Array):
	pass


"""
Wait for given time in seconds.
Usage: wait time_in_seconds
"""
func wait(command_params : Array):
	escoria.current_state = escoria.GAME_STATE.WAIT
	var time = float(command_params[0])
	if time <= 0:
		return esctypes.EVENT_LEVEL_STATE.RETURN
#	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "wait", time, p_level)
	escoria.main.wait(command_params, current_context)
	current_context.waiting = true
	return esctypes.EVENT_LEVEL_STATE.YIELD


"""
Make object1 walk towards object2. This command is not blocking (user input not disabled)
Usage: walk object_id1 object_id2
"""
func walk(command_params : Array):
	escoria.do("walk", command_params)


"""
"""
func walk_block(command_params : Array):
	pass






