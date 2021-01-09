extends Node

# Scripts
onready var esc_compiler = $esc_compiler
onready var logger = load("res://addons/escoria-core/game/core-scripts/log/logging.gd").new()
onready var main = $main
onready var esc_runner = $esc_runner
onready var esc_level_runner = $esc_runner/esc_level_runner
onready var inputs_manager = $inputs_manager
onready var utils = load("res://addons/escoria-core/game/core-scripts/utils/utils.gd").new()

# INSTANCES
var main_menu_instance
## Dialog player instantiator. This instance is called directly for dialogs.
var dialog_player 
## Inventory scene
var inventory

# Game variables
var room_terrain

enum GAME_STATE {
	DEFAULT,
	DIALOG,
	WAIT
}
onready var current_state = GAME_STATE.DEFAULT

##################################################################################
func _ready():
	pass


# Called by Main menu "start new game"
func new_game():
	var actions = esc_compiler.load_esc_file(ProjectSettings.get_setting("escoria/main/game_start_script"))
	$esc_runner.run_game(actions)


func change_scene_path(scene_path):
	var scene = load(scene_path).instance()
	get_tree().get_root().call_deferred("add_child", scene)
	return scene


func set_main_menu(scene):
	main_menu_instance = scene

func report_warnings(p_path : String, warnings : Array) -> void:
	var text = "Warnings in file "+p_path+"\n"
	for w in warnings:
		if w is Array:
			text += str(w)+"\n"
		else:
			text += w+"\n"
	printerr("warning is: ", text)


func report_errors(p_path : String, errors : Array) -> void:
	var text = "Errors in file "+p_path+"\n"
	for e in errors:
		if e is Array:
			text += str(e)+"\n"
		else:
			text += e+"\n"
	printerr("error is: ", text)
	if ProjectSettings.get_setting("escoria/debug/terminate_on_errors"):
		print_stack()
		assert(false)
		# If your game stopped here, you may want to look at the Output tab and check for 
		# the error that caused the game to stop.


"""
Add object to the environement.
"""
func register_object(object : Object):
	var object_id
	if object.get("global_id"):
		object_id = object.global_id
	else:
		object_id = object.name
		
	if object is ESCDialogsPlayer:
		dialog_player = object
		
	if object is ESCPlayer:
		$esc_runner.register_object(object_id, object, true)
		
	if object is ESCHotspot or object is Position2D:
		$esc_runner.register_object(object_id, object, true)
	
	if object is ESCItem:
		$esc_runner.register_object(object_id, object, true)
	
	if object is ESCTerrain:
		room_terrain = object
	
#	if object is ESCBackground:
#		$esc_runner.register_object(object_id, object, true)
	
	if object is ESCCamera:
		$esc_runner.register_object(object_id, object, true)
	
	if object is ESCInventory:
		inventory = object
		

"""
Generic action function that runs an action on an element of the room (eg player walk)
action: type of the action ()
"""
func do(action : String, params : Array = []) -> void:
	if current_state == GAME_STATE.DEFAULT:
		match action:
			"walk":
				# Reset current action. 
				esc_runner.set_current_action("")
				
				# Check moving object.
				if !escoria.esc_runner.check_obj(params[0], "escoria.do(walk)"):
					report_errors("escoria.gd:do()", 
						["Walk action requested on inexisting object: " + params[0]])
					return
				
				var moving_obj = escoria.esc_runner.get_object(params[0])
				
				# Walk to Position2D.
				if params[1] is Vector2:
					var target_position = params[1]
					var is_fast : bool = false
					if params.size() > 2 and params[2] == true:
						is_fast = true
					var walk_context = {"fast": is_fast} 
					moving_obj.walk_to(target_position, walk_context)
					
				# Walk to object from its id
				elif params[1] is String:
					if !escoria.esc_runner.check_obj(params[1], "escoria.do(walk)"):
						report_errors("escoria.gd:do()", 
							["Walk action requested TOWARDS inexisting object: " + params[1]])
						return
					
					var object = escoria.esc_runner.get_object(params[1])
					if object:
						var target_position : Vector2 = object.interact_position
						var is_fast : bool = false
						if params.size() > 2 and params[2] == true:
							is_fast = true
						var walk_context = {"fast": is_fast, "target_object" : object} 
						
						moving_obj.walk_to(target_position, walk_context)
							
			"hotspot_left_click", "item_left_click":
				if params[0] is String:
					printt("escoria.do : item_left_click on item ", params[0])
					
					# call : ev_left_click_on_item()
					ev_left_click_on_item($esc_runner.get_object(params[0]), params[1])
					
			"hotspot_right_click", "item_right_click":
				if params[0] is String:
					printt("escoria.do : item_right_click on item ", params[0])
					
					# call : ev_left_click_on_item()
					ev_left_click_on_item($esc_runner.get_object(params[0]), params[1], true)
				
			_:
#				$esc_runner.activate(action, params[0])
				report_warnings("escoria.gd:do()", ["Action received:", action, "with params ", params])
	elif current_state == GAME_STATE.DIALOG:
		dialog_player.finish_fast()
	elif current_state == GAME_STATE.WAIT:
		pass
		


# PRIVATE
func ev_left_click_on_item(obj, event, default_action = false):
	"""
	Event occurring when an object/item is left clicked
	obj : object that was left clicked
	event :
	"""
	if obj is String:
		obj = esc_runner.objects[obj]
	printt(obj.global_id, "left-clicked with", event)
	
	var need_combine = false
	# Check if current_action and current_tool are already set
	if esc_runner.current_action:
		if esc_runner.current_tool:
			if esc_runner.current_action in esc_runner.current_tool.combine_if_action_used_among:
				need_combine = true
			else:
				esc_runner.current_tool = obj
		else:
			if default_action:
				esc_runner.current_action = obj.default_action
			elif esc_runner.current_action in obj.combine_if_action_used_among:
				esc_runner.current_tool = obj
				
	
	var action = "walk"
	# Don't interact after player movement towards object (because object is inactive for example)
	var dont_interact = false
	var destination_position : Vector2 = main.current_scene.player.global_position
	
	# Create walk context 
	var walk_context = {"fast": event.doubleclick, "target_object" : obj}
	
	# If object not in inventory, player walks towards it
	if !esc_runner.inventory_has(obj.global_id):
		var clicked_object_has_interact_position = false

		if esc_runner.get_interactive(obj.global_id):
			if obj.interact_positions.default != null:
				destination_position = obj.interact_positions.default#.global_position
				clicked_object_has_interact_position = true
			else:
				destination_position = obj.position
		else:
			destination_position = event.position
			dont_interact = true
		
		main.current_scene.player.walk_to(destination_position, walk_context)
		
		# Wait for the player to arrive before continuing with action.
		yield(main.current_scene.player, "arrived")
	
	# If no interaction should happen after player has arrived, leave immediately.
	if dont_interact:
		return
	
	var player_global_pos = main.current_scene.player.global_position
	var clicked_position = event.position
	
	# If player has arrived at the position he was supposed to reach so he can interact
	if player_global_pos == destination_position:
		# Manage exits
		if obj.is_exit and $esc_runner.current_action == "" or $esc_runner.current_action == "walk":
			var params = [obj]
			$esc_runner.activate("exit_scene", params)
		
		else:
			# Manage movements towards object before activating it
			if $esc_runner.current_action == "" or $esc_runner.current_action == "walk":
				if destination_position != clicked_position \
						and !esc_runner.inventory_has(obj.global_id):
					esc_runner.activate("arrived", [obj])
			# Manage action on object
			elif $esc_runner.current_action != "" and $esc_runner.current_action != "walk":
				# If apply_interact, perform combine between items
				if need_combine:
					esc_runner.activate(esc_runner.current_action, [esc_runner.current_tool, obj])
						
				else:
					esc_runner.activate(esc_runner.current_action, [obj])
		
	else:
#		escoria.fallback("")
		pass
