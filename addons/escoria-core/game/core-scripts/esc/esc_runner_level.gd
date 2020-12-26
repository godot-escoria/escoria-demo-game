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
	
	if escoria.current_state == escoria.GAME_STATE.WAIT:
		escoria.current_state = escoria.GAME_STATE.DEFAULT


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
accept_input [ALL|NONE|SKIP] 
What type of input does the game accept. ALL is the default, SKIP allows skipping 
of dialog but nothing else, NONE denies all input. Including opening the menu etc. 
SKIP and NONE also disable autosaves. Note that SKIP gets reset to ALL when the 
event is done, but NONE persists. This allows you to create cut scenes with SKIP 
where the dialog can be skipped, but also initiate locked-down cutscenes with 
accept_input NONE in :setup and accept_input ALL later in :ready.
"""
func accept_input(command_params : Array):
#	var p_input = command_params[0]
#	var input = escoria.esc_runner.acceptable_inputs["INPUT_" + p_input]
#	escoria.esc_runner.set_accept_input(input)
	pass


"""
"""
func autosave():
#	escoria.request_autosave()
	pass


"""
anim object name [reverse] [flip_x] [flip_y] 
Executes the animation specificed with the "name" parameter on the object, 
without blocking. The next command in the event will be executed immediately after. 
Optional parameters:
	reverse plays the animation in reverse when true
	flip_x flips the x axis of the object's sprites when true (object's root node needs to be Node2D)
	flip_y flips the y axis of the object's sprites when true (object's root node needs to be Node2D)
"""
func anim(command_params : Array):
	if !check_obj(command_params[0], "anim"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	private_play_animation(command_params)
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
Groups Commands can be grouped using the character ">" to start a group, and 
incrementing the indentation of the commands that belong to the group. Example:
	>
		set_global door_open true
		animation player pick_up
	# end of group
"""
func branch(command_params : Array):
	var branch_ev = esctypes.ESCEvent.new("branch", command_params, [])
	return escoria.esc_runner.add_level(branch_ev, false)


"""
camera_push target [time] [type] 
Push camera to target. Target must have camera_pos set. 
If it's of type Camera2D, its zoom will be used as well as position. 
- A time value of 0 will set the camera immediately.
- type is any of the Tween.TransitionType values without the prefix, eg. LINEAR, 
	QUART or CIRC; defaults to QUART.
"""
func camera_push(command_params : Array):
	var target = escoria.esc_runner.get_object(command_params[0])
	var time = command_params[1] if command_params.size() > 1 else 1
	var type = command_params[2] if command_params.size() > 2 else "QUAD"
	escoria.main.current_scene.game.get_node("camera").push(target, time, type)


"""
camera_set_drag_margin_enabled h v 
- "h" and "v" are booleans for whether or not horizontal and vertical drag 
margins are enabled. You will likely want to set them false for advanced camera 
motions and true for regular gameplay and/or tracking NPCs.
"""
func camera_set_drag_margin_enabled():
	pass


"""
camera_set_pos speed x y 
Moves the camera to a position defined by "x" and "y", at the speed defined by 
"speed" in pixels per second. If speed is 0, camera is teleported to the position.
"""
func camera_set_pos():
	pass


"""
camera_set_target speed object [object2 object3 ...] 
Configures the camera to follow 1 or more objects, using "speed" as speed limit. 
This is the default behavior (default follow object is "player"). 
If there's more than 1 object, the camera follows the average position of all 
the objects specified.
"""
func camera_set_target():
	pass


"""
camera_set_zoom magnitude [time] 
Zooms the camera in/out to the desired magnitude. Values larger than 1 zooms 
the camera out, and smaller values zooms in, relative to the default value of 1. 
An optional time in seconds controls how long it takes for the camera to zoom 
into position.
"""
func camera_set_zoom():
	pass


"""
camera_set_zoom_height pixels [time] 
Similar to the command abo/ve, but uses pixel height instead of magnitude to zoom.
"""
func camera_set_zoom_height():
	pass


"""
camera_shift x y [time] [type] 
Shift camera by x and y pixels over time seconds. 
- type is any of the Tween.TransitionType values without the prefix, eg. LINEAR, 
	QUART or CIRC; defaults to QUART.
"""
func camera_shift():
	pass


"""
change_scene path [run_events]
Loads a new scene, specified by "path". 
The run_events variable is a boolean (default true) which you never want to set 
manually! It's there only to benefit save games, so they don't conflict with the 
scene's events.
"""
func change_scene(command_params : Array):
	# Savegames must have events disabled, so saving the game adds a false to params
	var run_events = true
	if command_params.size() == 2:
		run_events = bool(command_params[1])
	
	# looking for localized string format in scene. this should be somewhere else
	var sep = command_params[0].find(":\"")
	if sep >= 0:
		var path = command_params[0].substr(sep + 2, command_params[0].length() - (sep + 2))
		escoria.esc_runner.call_deferred("change_scene", [path], current_context, run_events)
	else:
		escoria.esc_runner.call_deferred("change_scene", command_params, current_context, run_events)
	
	current_context.waiting = true
	return esctypes.EVENT_LEVEL_STATE.YIELD


"""
"""
func custom():
	pass


"""
cut_scene object name [reverse] [flip_x] [flip_y] 
Executes the animation specificed with the "name" parameter on the object, BLOCKING. 
The next command in the event will be executed when the animation is finished 
playing. 
Optional parameters:
- reverse plays the animation in reverse when true
- flip_x flips the x axis of the object's sprites when true 
	(object's root node needs to be Node2D)
- flip_y flips the y axis of the object's sprites when true 
	(object's root node needs to be Node2D)
"""
func cut_scene(command_params : Array):
	if !check_obj(command_params[0], "cut_scene"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	private_play_animation(command_params)
	return esctypes.EVENT_LEVEL_STATE.YIELD


"""
PRIVATE
Play animation using parameters.
Used by commands anim() and cut_scene() 
"""
func private_play_animation(command_params : Array):
	var obj = escoria.esc_runner.get_object(command_params[0])
	var anim_id = command_params[1]
	var reverse = false
	if command_params.size() > 2:
		reverse = command_params[2]
	var flip = Vector2(1, 1)
	if command_params.size() > 3 && command_params[3]:
		flip.x = -1
	if command_params.size() > 4 && command_params[4]:
		flip.y = -1
	current_context.waiting = true
	obj.play_anim(anim_id, current_context, reverse, flip)


"""
debug string [string2 ...] 
	Takes 1 or more strings, prints them to the console.
"""
func debug(command_params : Array):
	for p in command_params:
		printt(p)
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
dec_global name value 
	Subtracts the value from global with given "name". 
	Value and global must both be integers.
"""
func dec_global(command_params : Array):
	escoria.esc_runner.dec_global(command_params[0], command_params[1])
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
inc_global name value 
	Adds the value to global with given "name". 
	Value and global must both be integers.
"""
func inc_global(command_params : Array):
	escoria.esc_runner.inc_global(command_params[0], command_params[1])
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
Start a dialog choice.
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


#func dialog_config():
##	escoria.esc_runner.dialog_config(params)
##	return esctypes.EVENT_LEVEL_STATE.RETURN
#	pass


"""
enable_terrain node_name
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
Adds element in inventory.
Usage: inventory_add my_item
equivalent to: set_global i/my_item true
"""
func inventory_add(command_params : Array):
	set_global(["i/"+command_params[0], "true"])


"""
Removes element from inventory.
Usage: inventory_remove my_item
equivalent to: set_global i/my_item false
"""
func inventory_remove(command_params : Array):
	set_global(["i/"+command_params[0], "false"])


"""
TODO: This is dependant to the user UI. It must remain flexible enough.
"""
func inventory_open(command_params : Array):
	pass


"""
"""
func jump(command_params : Array):
#	escoria.esc_runner.jump(command_params[0])
#	return esctypes.EVENT_LEVEL_STATE.JUMP
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
func set_angle(command_params : Array):
	if !check_obj(command_params[0], "set_angle"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	var obj = escoria.esc_runner.get_object(command_params[0])
	obj.set_angle(int(command_params[1]))
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
set_globals pattern value
Changes the value of multiple globals using a wildcard pattern. 
Example:
	# clears the inventory
	set_globals i/* false
"""
func set_globals(command_params : Array):
	var pattern : String = command_params[0]
	var val = command_params[1]
	escoria.esc_runner.set_globals(pattern, val)


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
func teleport(command_params : Array):
	if !check_obj(command_params[0], "teleport"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	if !check_obj(command_params[1], "teleport"):
		return esctypes.EVENT_LEVEL_STATE.RETURN

	var angle
	if command_params.size() > 2:
		angle = int(command_params[2])

	escoria.esc_runner.get_object(command_params[0]) \
		.teleport(escoria.esc_runner.get_object(command_params[1]), angle)
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






