# The escorie main script
extends Node


# Current game state
# * DEFAULT: Common game function
# * DIALOG: Game is playing a dialog
# * WAIT: Game is waiting
enum GAME_STATE {
	DEFAULT,
	DIALOG,
	WAIT
}


# Logger used
var logger: ESCLogger

# Several utilities
var utils: ESCUtils

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

# Resource cache handler
var resource_cache: ESCResourceCache

# Instance of the main menu
var main_menu_instance

# Terrain of the current room
var room_terrain

# Dialog player instantiator. This instance is called directly for dialogs.
var dialog_player 

# Inventory scene
var inventory

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
	# Music volume (max is 1.0)
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


# The current state of the game
onready var current_state = GAME_STATE.DEFAULT

# The game resolution
onready var game_size = get_viewport().size

# The main scene
onready var main = $main

# The escoria inputs manager
onready var inputs_manager = $inputs_manager

# Savegame management
onready var save_data = load("res://addons/escoria-core/game/core-scripts/save_data/save_data.gd").new()


# Initialize various objects
func _init():
	self.logger = ESCLogger.new()
	self.utils = ESCUtils.new()
	self.inventory_manager = ESCInventoryManager.new()
	self.action_manager = ESCActionManager.new()
	self.event_manager = ESCEventManager.new()
	self.globals_manager = ESCGlobalsManager.new()
	self.add_child(self.event_manager)
	self.object_manager = ESCObjectManager.new()
	self.command_registry = ESCCommandRegistry.new()
	self.esc_compiler = ESCCompiler.new()
	self.resource_cache = ESCResourceCache.new()
	self.resource_cache.start()


# Load settings
func _ready():
	save_data.start()
	save_data.check_settings()
	var settings = save_data.load_settings(null)
	escoria.settings = parse_json(settings)
	escoria._on_settings_loaded(escoria.settings)


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


# Run a generic action
#
# #### Parameters
#
# - action: type of the action to run
# - params: Parameters for the action
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
							"Walk action requested on inexisting " + \
							"object: %s " % params[0]
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
					var walk_context = ESCWalkContext.new(
						null,
						target_position,
						is_fast
					) 
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
						var target_position : Vector2 = \
								object.node.interact_position
						var is_fast : bool = false
						if params.size() > 2 and params[2] == true:
							is_fast = true
						var walk_context = ESCWalkContext.new(
							object, 
							Vector2(), 
							is_fast
						)
						
						moving_obj.walk_to(target_position, walk_context)
							
			"item_left_click":
				if params[0] is String:
					self.logger.info(
						"escoria.do() : item_left_click on item ", 
						[params[0]]
					)
					var item = self.object_manager.get_object(params[0])
					_ev_left_click_on_item(item, params[1])
					
			"item_right_click":
				if params[0] is String:
					self.logger.info(
						"escoria.do() : item_right_click on item ", 
						[params[0]]
					)
					var item = self.object_manager.get_object(params[0])
					_ev_left_click_on_item(item, params[1], true)
			
			"trigger_in":
				var trigger_id = params[0]
				var object_id = params[1]
				var trigger_in_verb = params[2]
				self.logger.info("escoria.do() : trigger_in %s by %s" % [
					trigger_id,
					object_id
				])
				self.event_manager.queue_event(
					object_manager.get_object(trigger_id).events[
						trigger_in_verb
					]
				)
			
			"trigger_out":
				var trigger_id = params[0]
				var object_id = params[1]
				var trigger_out_verb = params[2]
				self.logger.info("escoria.do() : trigger_out %s by %s" % [
					trigger_id,
					object_id
				])
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


# Event handler when an object/item was clicked
# FIXME this method is way to complex
#
# #### Parameters
#
# - ob: Object that was left clicked
# - event: Input event that was received
# - default_action: Run the inventory default action
func _ev_left_click_on_item(obj, event, default_action = false):
	if obj is String:
		obj = object_manager.get_object(obj)
	self.logger.info(obj.global_id + " left-clicked with event ", [event])
	
	var need_combine = false
	# Check if current_action and current_tool are already set
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
				
	
	# Don't interact after player movement towards object 
	# (because object is inactive for example)
	var dont_interact = false
	var destination_position : Vector2 = main.current_scene.player.\
			global_position
	
	# Create walk context 
	var walk_context = ESCWalkContext.new(
		obj,
		Vector2(),
		event.doubleclick
	)
	
	# If object not in inventory, player walks towards it
	if not inventory_manager.inventory_has(obj.global_id):
		var clicked_object_has_interact_position = false

		if object_manager.get_object(obj.global_id).interactive:
			if obj.node.get_interact_position() != null:
				destination_position = obj.node.get_interact_position()
				clicked_object_has_interact_position = true
			else:
				destination_position = obj.node.position
		else:
			destination_position = event.position
			dont_interact = true
		
		main.current_scene.player.walk_to(
			destination_position, 
			walk_context
		)
		
		# Wait for the player to arrive before continuing with action.
		var context: ESCWalkContext = yield(
			main.current_scene.player,
			"arrived"
		)
		
		self.logger.info("Context arrived: ", [context])
		
		if context.target_object and \
				context.target_object.global_id != walk_context.\
				target_object.global_id:
			dont_interact = true
		elif context.target_position != walk_context.target_position:
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


# Apply the loaded settings
#
# #### Parameters
#
# * p_settings: Loaded settings
func _on_settings_loaded(p_settings : Dictionary) -> void:
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
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"), 
		linear2db(settings.master_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear2db(settings.sfx_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), 
		linear2db(settings.music_volume)
	)
	TranslationServer.set_locale(settings.text_lang)
#	music_volume_changed()


