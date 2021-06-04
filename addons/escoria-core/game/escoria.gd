extends Node

# Scripts
onready var main = $main
onready var inputs_manager = $inputs_manager
onready var utils = load("res://addons/escoria-core/game/core-scripts/utils/utils.gd").new()
onready var save_data = load("res://addons/escoria-core/game/core-scripts/save_data/save_data.gd").new()

# Logger used
var logger: ESCLogger

# The inventory manager instance
var inventory_manager: ESCInventoryManager

# The action manager instance
var action_manager: ESCActionManager

# ESC compiler instance
var esc_compiler: ESCCompiler

# ESC Event manager instance
var event_manager: ESCEventManager

# ESC globals registry instance
var globals_manager: ESCGlobalsManager

# ESC object manager instance
var object_manager: ESCObjectManager

# ESC command registry instance
var command_registry: ESCCommandRegistry

var resource_cache: ResourceCache

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

onready var game_size = get_viewport().size

# These are settings that the player can affect and save/load later
var settings : Dictionary
# These are default settings
var settings_default : Dictionary = {
	# Text language
	"text_lang": ProjectSettings.get_setting("escoria/main/text_lang"),
	# Voice language
	"voice_lang": ProjectSettings.get_setting("escoria/main/voice_lang"),
	# Speech enabled
	"speech_enabled": ProjectSettings.get_setting("escoria/sound/speech_enabled"),
	# Master volume (max is 1.0)
	"master_volume": ProjectSettings.get_setting("escoria/sound/master_volume"),
	# Music volume (max is 1.0)
	"music_volume": ProjectSettings.get_setting("escoria/sound/music_volume"),
	# Sound effects volume (max is 1.0)
	"sfx_volume": ProjectSettings.get_setting("escoria/sound/sfx_volume"),
	# Voice volume (for speech only, max is 1.0)
	"voice_volume": ProjectSettings.get_setting("escoria/sound/speech_volume"),
	# Set fullscreen
	"fullscreen": false,
	# Allow dialog skipping
	"skip_dialog": true,
	# XXX: What is this? `achievements.gd` looks like iOS-only
	"rate_shown": false,
}


func _init():
	self.logger = ESCLogger.new()
	self.inventory_manager = ESCInventoryManager.new()
	self.action_manager = ESCActionManager.new()
	self.event_manager = ESCEventManager.new()
	self.globals_manager = ESCGlobalsManager.new()
	self.add_child(self.event_manager)
	self.object_manager = ESCObjectManager.new()
	self.command_registry = ESCCommandRegistry.new()
	self.esc_compiler = ESCCompiler.new()
	self.resource_cache = ResourceCache.new()
	self.resource_cache.start()


func _ready():
	save_data.start()
	save_data.check_settings()
	var settings = save_data.load_settings(null)
	escoria.settings = parse_json(settings)
	escoria._on_settings_loaded(escoria.settings)


##################################################################################

# Called by Main menu "start new game"
func new_game():
	var script = self.esc_compiler.load_esc_file(
		ProjectSettings.get_setting("escoria/main/game_start_script")
	)
	event_manager.queue_event(script.events["start"])
	var rc = yield(event_manager, "event_finished")
	while rc[1] != "start":
		rc = yield(event_manager, "event_finished")
	
	if rc[0] != ESCExecution.RC_OK:
		self.logger.report_errors(
			"Start event of the start script returned unsuccessful: %d" % rc[0],
			[]
		)
		return
	

"""
Generic action function that runs an action on an element of the room (eg player walk)
action: type of the action ()
"""
func do(action : String, params : Array = []) -> void:
	if current_state == GAME_STATE.DEFAULT:
		match action:
			"walk":
				self.action_manager.clear_current_action()
				
				# Check moving object.
				if not self.object_manager.has(params[0]):
					self.logger.report_errors(
						"escoria.gd:do()", 
						[
							"Walk action requested on inexisting object: %s "\
									 % params[0]
						]
					)
					return
				
				var moving_obj = self.object_manager.get_object(params[0])\
						.node
				
				# Walk to Position2D.
				if params[1] is Vector2:
					var target_position = params[1]
					var is_fast : bool = false
					if params.size() > 2 and params[2] == true:
						is_fast = true
					var walk_context = {"fast": is_fast, "target": target_position} 
					moving_obj.walk_to(target_position, walk_context)
					
				# Walk to object from its id
				elif params[1] is String:
					if not self.object_manager.has(params[1]):
						self.logger.report_errors(
							"escoria.gd:do()", 
							[
								"Walk action requested TOWARDS " +\
								"inexisting object: %s" % params[1]
							]
						)
						return
					
					var object = self.object_manager.get_object(params[1])
					if object:
						var target_position : Vector2 = object.node.interact_position
						var is_fast : bool = false
						if params.size() > 2 and params[2] == true:
							is_fast = true
						var walk_context = {"fast": is_fast, "target_object" : object} 
						
						moving_obj.walk_to(target_position, walk_context)
							
			"item_left_click":
				if params[0] is String:
					self.logger.info("escoria.do() : item_left_click on item ", [params[0]])
					var item = self.object_manager.get_object(params[0])
					ev_left_click_on_item(item, params[1])
					
			"item_right_click":
				if params[0] is String:
					self.logger.info("escoria.do() : item_right_click on item ", [params[0]])
					var item = self.object_manager.get_object(params[0])
					ev_left_click_on_item(item, params[1], true)
			
			"trigger_in":
				var trigger_id = params[0]
				var object_id = params[1]
				var trigger_in_verb = params[2]
				self.logger.info("escoria.do() : trigger_in " + trigger_id + " by " + object_id)
				self.event_manager.queue_event(
					object_manager.get_object(trigger_id).events[
						trigger_in_verb
					]
				)
			
			"trigger_out":
				var trigger_id = params[0]
				var object_id = params[1]
				var trigger_out_verb = params[2]
				self.logger.info("escoria.do() : trigger_out " + trigger_id + " by " + object_id)
				self.event_manager.queue_event(
					object_manager.get_object(trigger_id).events[
						trigger_out_verb
					]
				)
			
			_:
				self.logger.report_warnings("escoria.gd:do()", 
					["Action received:", action, "with params ", params])
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
		obj = object_manager.get_object(obj)
	self.logger.info(obj.global_id + " left-clicked with event ", [event])
	
	var need_combine = false
	# Check if current_action and current_tool are already set
	if self.action_manager.current_action:
		if self.action_manager.current_tool:
			if self.action_manager.current_action in self.action_manager\
					.current_tool.node.combine_if_action_used_among:
				need_combine = true
			else:
				self.action_manager.current_tool = obj
		else:
			if default_action:
				if self.inventory_manager.inventory_has(obj.global_id):
					self.action_manager.current_action = \
							obj.node.default_action_inventory
				else:
					self.action_manager.current_action = \
							obj.node.default_action
			elif self.action_manager.current_action in \
					obj.node.combine_if_action_used_among:
				self.action_manager.current_tool = obj
				
	
	# Don't interact after player movement towards object (because object is inactive for example)
	var dont_interact = false
	var destination_position : Vector2 = main.current_scene.player.global_position
	
	# Create walk context 
	var walk_context = {"fast": event.doubleclick, "target_object" : obj.node}
	
	# If object not in inventory, player walks towards it
	if not inventory_manager.inventory_has(obj.global_id):
		var clicked_object_has_interact_position = false

		if object_manager.get_object(obj.global_id).interactive:
#			if obj.interact_positions.default != null:
#				destination_position = obj.interact_positions.default#.global_position
#				clicked_object_has_interact_position = true
#			else:
#				destination_position = obj.position
			if obj.node.get_interact_position() != null:
				destination_position = obj.node.get_interact_position()
				clicked_object_has_interact_position = true
			else:
				destination_position = obj.node.position
		else:
			destination_position = event.position
			dont_interact = true
		
		# Use ESC for this?
		var is_already_walking = main.current_scene.player.walk_to(destination_position, walk_context)
		
		# Wait for the player to arrive before continuing with action.
		var context = yield(main.current_scene.player, "arrived")
		self.logger.info("Context arrived: ", [context])
		if context.has("target_object") and walk_context.has("target_object"):
			if (context.target_object.global_id != walk_context.target_object.global_id) \
				or (context.target_object.global_id == walk_context.target_object.global_id and is_already_walking):
				dont_interact = true
		elif context.has("target") and walk_context.has("target"):
			if (context.target.global_id != walk_context.target.global_id) \
				or (context.target.global_id == walk_context.target.global_id and is_already_walking):
				dont_interact = true
	
	# If no interaction should happen after player has arrived, leave immediately.
	if dont_interact:
		return
	
	var player_global_pos = main.current_scene.player.global_position
	var clicked_position = event.position
	
	# If player has arrived at the position he was supposed to reach so he can interact
	if player_global_pos == destination_position:
		# Manage exits
		if obj.node.is_exit and self.action_manager.current_action == "" \
				or self.action_manager.current_action == "walk":
			self.action_manager.activate("exit_scene", obj)
		else:
			# Manage movements towards object before activating it
			if self.action_manager.current_action == "" \
					or self.action_manager.current_action == "walk":
				if destination_position != clicked_position \
						and not inventory_manager.inventory_has(obj.global_id):
					self.action_manager.activate("arrived", obj)
			# Manage action on object
			elif self.action_manager.current_action != "" and \
					self.action_manager.current_action != "walk":
				# If apply_interact, perform combine between items
				if need_combine:
					self.action_manager.activate(
						self.action_manager.current_action, 
						self.action_manager.current_tool, 
						obj
					)
						
				else:
					self.action_manager.activate(
						self.action_manager.current_action, 
						obj
					)
		
#	else:
##		escoria.fallback("")
#		pass

func _on_settings_loaded(p_settings : Dictionary):
	escoria.logger.info("******* settings loaded", p_settings)
	if p_settings != null:
		settings = p_settings
	else:
		settings = {}

	for k in settings_default:
		if !(k in settings):
			settings[k] = settings_default[k]

	# TODO Apply globally
#	AudioServer.set_fx_global_volume_scale(settings.sfx_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(settings.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear2db(settings.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(settings.music_volume))
	TranslationServer.set_locale(settings.text_lang)
#	music_volume_changed()


