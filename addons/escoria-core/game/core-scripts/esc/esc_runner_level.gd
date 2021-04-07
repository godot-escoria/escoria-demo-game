extends Node

# This script implements the ESCCommands contained in the ESCEvent.
# TODO : this script should use "Command" pattern.

var current_context


func finished(context = null):
	if context != null:
		context.waiting = false
	else:
		current_context.waiting = false
	
	if escoria.current_state == escoria.GAME_STATE.WAIT:
		escoria.current_state = escoria.GAME_STATE.DEFAULT


func resume(context):
	current_context = context
	if context.waiting:
		return esctypes.EVENT_LEVEL_STATE.YIELD
	var count = context.instructions.size()
	while context.ip < count:
		var top = escoria.esc_runner.levels_stack.size()
		var ret = run(context)
		context.ip += 1
		if top < escoria.esc_runner.levels_stack.size():
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
	if !escoria.esc_runner.test(cmd):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	#print("name is ", cmd.name)
	#if !(cmd.name in self):
	#	escoria.logger.report_errors("", ["Unexisting command "+cmd.name])
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
	if !escoria.esc_runner.check_obj(command_params[0], "anim"):
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
	escoria.esc_runner.get_object("camera").push(target, time, type)


"""
camera_set_limits camlimits_id 
Sets the camera limits to the one defined under "camlimits_id" in ESCRoom's 
camera_limits array.
- camlimits_id : int : id of the camera limits to apply (defined in ESCRoom's 
camera_limits array)
"""
func camera_set_limits(command_params : Array):
	escoria.main.set_camera_limits(command_params[0])


"""
camera_set_drag_margin_enabled horizontal_enabled vertical_enabled 
- horizontal_enabled : bool
- vertical_enabled : bool are booleans for whether or not horizontal and vertical drag 
margins are enabled. You will likely want to set them false for advanced camera 
motions and true for regular gameplay and/or tracking NPCs.
"""
func camera_set_drag_margin_enabled(command_params : Array):
	var horizontal_enabled = command_params[0]
	var vertical_enabled = command_params[1]
	escoria.esc_runner.get_object("camera").set_drag_margin_enabled(horizontal_enabled, vertical_enabled)


"""
camera_set_pos speed x y 
Moves the camera to a position defined by "x" and "y", at the speed defined by 
"speed" in pixels per second. If speed is 0, camera is teleported to the position.
"""
func camera_set_pos(command_params : Array):
	var speed = command_params[0]
	var pos = Vector2(command_params[1], command_params[2])
	escoria.esc_runner.get_object("camera").set_target(pos, speed)
	

"""
camera_set_target speed object [object2 object3 ...] 
Configures the camera to follow 1 or more objects, using "speed" as speed limit. 
This is the default behavior (default follow object is "player"). 
If there's more than 1 object, the camera follows the average position of all 
the objects specified.
"""
func camera_set_target(command_params : Array):
	var speed = command_params[0]
	var target = escoria.esc_runner.get_object(command_params[1])
	escoria.esc_runner.get_object("camera").set_target(target, speed)


"""
camera_set_zoom magnitude [time] 
Zooms the camera in/out to the desired magnitude. Values larger than 1 zooms 
the camera out, and smaller values zooms in, relative to the default value of 1. 
An optional time in seconds controls how long it takes for the camera to zoom 
into position.
"""
func camera_set_zoom(command_params : Array):
	var zoom_level = command_params[0]
	var speed = command_params[0] if command_params.size() > 1 else 0
	escoria.esc_runner.get_object("camera").set_camera_zoom(zoom_level, speed)


"""
camera_set_zoom_height pixels [time] 
Similar to the command above, but uses pixel height instead of magnitude to zoom.
"""
func camera_set_zoom_height(command_params : Array):
	var magnitude = command_params[0] / escoria.game_size.y
	var time = command_params[1] if command_params.size() > 1 else 0
	escoria.esc_runner.get_object("camera").set_camera_zoom(magnitude, float(time))


"""
camera_shift x y [time] [type] 
Shift camera by x and y pixels over time seconds. 
- type is any of the Tween.TransitionType values without the prefix, eg. LINEAR, 
	QUART or CIRC; defaults to QUART.
"""
func camera_shift(command_params : Array):
	var x = command_params[0]
	var y = command_params[1]
	var time = command_params[2]
	var type = command_params[3] if command_params.size() > 3 else "QUAD"
	escoria.esc_runner.get_object("camera").shift(x, y, time, type)


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
	if !escoria.esc_runner.check_obj(command_params[0], "cut_scene"):
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
inventory_open true/false
Shows or hides inventory. Uses code in game.tscn scene, thus developed outside of Escoria.
"""
func inventory_display(command_params : Array):
	var display : bool = bool(command_params[0])
	if display:
		escoria.main.current_scene.game.open_inventory()
	else:
		escoria.main.current_scene.game.close_inventory()


"""
jump label_name
Jump to label_name block. This is used to build more complex dialog trees.
Labels must be defined at the same level as the 'jump' command, using either
'label label_name' command or '% label_name'.
"""
func jump(command_params : Array):
	escoria.esc_runner.jump(command_params[0])
	return esctypes.EVENT_LEVEL_STATE.JUMP


"""
set_sound_state bg_music|bg_sound off|default|<path/to/music.file> true|false
"""
func set_sound_state(command_params : Array):
	var snd_player = command_params[0]
	var snd_id = command_params[1]
	var loop = false
	if command_params.size() == 3 and command_params[2]:
		loop = true
	escoria.main.get_node(snd_player).set_state(snd_id, loop)
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
queue_animation object animation
"""
func queue_animation(command_params : Array):
	pass


"""
queue_resource path [front_of_queue]
Queues the load of a resource in a background thread. The path must be a full 
path inside your game, for example "res://scenes/next_scene.tscn". 
The "front_of_queue" parameter is optional (default value false), to put the 
resource in the front of the queue. Queued resources are cleared when a change 
scene happens (but after the scene is loaded, meaning you can queue resources 
that belong to the next scene).
"""
func queue_resource(command_params : Array):
	var path : String = command_params[0]
	var in_front : bool = command_params[1] if command_params.size() > 1 else false
	escoria.esc_runner.resource_cache.queue_resource(path, in_front)


"""
repeat
Restarts the execution of the current scope at the start. A scope can be a group
or an event.
"""
func repeat(command_params : Array):
	return esctypes.EVENT_LEVEL_STATE.REPEAT


"""
say speaker_id "text_to_say" [dialog_ui_name]
Make a character say one line.
- dialog_ui_name String if set, uses the dialog UI by its name as defined 
	in game.tscn/dialog_layer/dialog_player
"""
func say(command_params : Array) -> esctypes:
	current_context.waiting = true
	
	var dict : Dictionary
	var dialog_scene_name = ProjectSettings.get_setting("escoria/ui/default_dialog_scene")
	
	if dialog_scene_name.empty():
		escoria.logger.report_errors("level_esc_runners.gd:say()", 
			["Project setting 'escoria/ui/default_dialog_scene' is not set.", 
			"Please set a default dialog scene."])
	var file = dialog_scene_name.get_file()
	var extension = dialog_scene_name.get_extension()
	dialog_scene_name = file.rstrip("." + extension)
	
	# Manage specific dialog scene
	if command_params.size() > 2:
		dialog_scene_name = command_params[2]
	
	# Manage translation/voice lines keys in the form of :
	#	line_key:"Default line text"
	# If a line_key exists, we'll set it a label as it will automatically be
	# translated
	var dialog_key_line = command_params[1].split(":", true, 1)
	if dialog_key_line.size() > 1:
		dialog_key_line[1] = dialog_key_line[1].trim_prefix("\"")
	
	dict = {
		"key": dialog_key_line[0],
		"line": dialog_key_line[1] if dialog_key_line.size() > 1 else dialog_key_line[0],
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
set_active global_id true/false
Sets object as active or inactive. Active objects are displayed in scene and 
respond to inputs. Inactives are hidden.
"""
func set_active(command_params : Array):
	if !escoria.esc_runner.check_obj(command_params[0], "set_active"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	var name : String = command_params[0]
	var value = command_params[1]
	escoria.esc_runner.set_active(name, value)

"""
set_angle object_id angle_degrees
Set the angle of an object. 
"""
func set_angle(command_params : Array):
	if !escoria.esc_runner.check_obj(command_params[0], "set_angle"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	var obj = escoria.esc_runner.get_object(command_params[0])
	# HACK Countering the fact that angle_to_point() function gives
	# angle against X axis not Y, we need to check direction using (angle-90°).
	# Since the ESC command already gives the right angle, we add 90.
	obj.set_angle(int(command_params[1] + 90))
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
set_state object_id state_name
Set object state to state_name. States are recorded in escoria.states[].
If the object has an animation named 'state_name', Escoria plays it.
"""
func set_state(command_params : Array):
	var global_id : String = command_params[0]
	var p_params : Array = command_params.slice(1, command_params.size())
	escoria.esc_runner.set_state(global_id, p_params)


"""
set_hud_visible true/false
Hides the UI. Uses code in game.tscn scene, thus developed outside of Escoria.
"""
func set_hud_visible(command_params : Array):
	if command_params[0]:
		escoria.main.current_scene.game.show_ui()
	else:
		escoria.main.current_scene.game.hide_ui()


"""
"""
func sched_event(command_params : Array):
	pass


"""
set_global global_variable value 
Sets a global variable value. Value can be string, integer or boolean.
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
set_interactive global_id true/false
Sets object as interactive or not. Interactive objects can be pointed and 
interacted with.
"""
func set_interactive(command_params : Array):
	var global_id : String = command_params[0]
	var value = command_params[1]
	escoria.esc_runner.set_interactive(global_id, value)


"""
set_speed global_id speed_value
Sets the speed of object defined by 'global_id' to 'speed_value'
"""
func set_speed(command_params : Array):
	if !escoria.esc_runner.check_obj(command_params[0], "set_speed"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	
	var global_id : String = command_params[0]
	var speed_value = command_params[1]
	escoria.get_object(global_id).set_speed(speed_value)


"""
"""
func slide(command_params : Array):
	pass


"""
"""
func slide_to_pos(command_params : Array):
	pass


"""
"""
func slide_block(command_params : Array):
	pass


"""
"""
func slide_to_pos_block(command_params : Array):
	pass


"""
spawn path [object2]
Instances a scene determined by "path", and places in the position of object2 
(object2 is optional)
"""
func spawn(command_params : Array):
	superpose_scene(command_params)

"""
stop
Stops the execution of the current script when it reaches the 'stop' instruction.
Usually used in the end of commands blocks.
"""
func stop(command_params : Array):
	return esctypes.EVENT_LEVEL_STATE.BREAK


"""
superpose_scene path [run_events]
Loads a new scene, specified by "path" and displays it OVER the current one. 
This is useful to display puzzle scenes over the current room, so that you don't 
loose any progression and continuity.
- path String Path to the scene to superpose.
- run_events Boolean (default true) which you never want to set 
manually! It's there only to benefit save games, so they don't conflict with the 
scene's events.
"""
func superpose_scene(command_params : Array):
	# Savegames must have events disabled, so saving the game adds a false to params
	var run_events = true
	if command_params.size() == 2:
		if command_params[1] in ["true", "false"]:
			run_events = true if command_params[1] == "true" else false
		else:
			current_context["set_position"] = command_params[1]
	
	# looking for localized string format in scene. this should be somewhere else
	var sep = command_params[0].find(":\"")
	if sep >= 0:
		var path = command_params[0].substr(sep + 2, command_params[0].length() - (sep + 2))
		escoria.esc_runner.call_deferred("superpose_scene", [path], current_context, run_events)
	else:
		escoria.esc_runner.call_deferred("superpose_scene", command_params, current_context, run_events)
	
	current_context.waiting = true
	return esctypes.EVENT_LEVEL_STATE.YIELD


"""
teleport obj1 obj2 [angle_degrees]
Teleports obj1 at obj2's position. If angle_degrees is set (int), sets obj1's 
angle to angle_degrees.
"""
func teleport(command_params : Array):
	if !escoria.esc_runner.check_obj(command_params[0], "teleport"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	if !escoria.esc_runner.check_obj(command_params[1], "teleport"):
		return esctypes.EVENT_LEVEL_STATE.RETURN

	var angle
	if command_params.size() > 2:
		angle = int(command_params[2])

	escoria.esc_runner.get_object(command_params[0]) \
		.teleport(escoria.esc_runner.get_object(command_params[1]), angle)
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
teleport obj1 x y [angle_degrees]
Teleports obj1 at (x,y). If angle_degrees is set (int), sets obj1's 
angle to angle_degrees.
"""
func teleport_pos(command_params : Array):
	if !escoria.esc_runner.check_obj(command_params[0], "teleport"):
		return esctypes.EVENT_LEVEL_STATE.RETURN
	var x = command_params[1]
	var y = command_params[2]

	var angle
	if command_params.size() > 2:
		angle = int(command_params[3])

	escoria.esc_runner.get_object(command_params[0]).teleport(Vector2(x,y), angle)
	return esctypes.EVENT_LEVEL_STATE.RETURN


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
walk object_id1 object_id2
Make object1 walk towards object2. This command is not blocking (user input not disabled)
"""
func walk(command_params : Array):
	current_context.waiting = false
	escoria.do("walk", command_params)
	return esctypes.EVENT_LEVEL_STATE.RETURN


"""
walk_block object_id1 object_id2
Make object1 walk towards object2. This command is blocking (user input disabled)
"""
func walk_block(command_params : Array):
	current_context.waiting = true
	escoria.do("walk", command_params)
	return esctypes.EVENT_LEVEL_STATE.YIELD


"""
walk_to_pos object_id1 pos_x pos_y
Make object1 walk towards object2. This command is not blocking (user input not disabled)
"""
func walk_to_pos(command_params : Array):
	current_context.waiting = false
	var destination_pos = Vector2(command_params[1], command_params[2])
	escoria.do("walk", [command_params[0], destination_pos])
	return esctypes.EVENT_LEVEL_STATE.RETURN
	
"""
walk_to_pos_block object_id1 pos_x pos_y
Make object1 walk towards object2. This command is blocking (user input disabled)
"""
func walk_to_pos_block(command_params : Array):
	current_context.waiting = true
	var destination_pos = Vector2(command_params[1], command_params[2])
	escoria.do("walk", [command_params[0], destination_pos])
	return esctypes.EVENT_LEVEL_STATE.YIELD










