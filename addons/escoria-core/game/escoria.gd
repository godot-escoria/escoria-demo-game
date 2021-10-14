# The escoria main script
extends Node

# Signal sent when pause menu has to be displayed
signal request_pause_menu


# Escoria version number
const ESCORIA_VERSION = "0.1.0"

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

# Terrain of the current room
var room_terrain

# Dialog player instantiator. This instance is called directly for dialogs.
var dialog_player: ESCDialogsPlayer

# Inventory scene
var inventory

# These are settings that the player can affect and save/load later
var settings: ESCSaveSettings

# The current state of the game
onready var current_state = GAME_STATE.DEFAULT

# The game resolution
onready var game_size = get_viewport().size

# The main scene
onready var main = $main

# The escoria inputs manager
var inputs_manager: ESCInputsManager

# Savegames and settings manager
var save_manager: ESCSaveManager

# The controller in charge of converting an action verb on a game object
# into an actual action
var controller: ESCController

# The game scene loaded
var game_scene: ESCGame

# The compiled start script loaded from ProjectSettings 
# escoria/main/game_start_script
var start_script : ESCScript



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
	self.save_manager = ESCSaveManager.new()
	self.inputs_manager = ESCInputsManager.new()
	self.controller = ESCController.new()
	
	settings = ESCSaveSettings.new()
	
	if ProjectSettings.get_setting("escoria/ui/game_scene") == "":
		logger.report_errors("escoria.gd", 
			["Parameter escoria/ui/game_scene is not set!"]
		)
	else:
		self.game_scene = resource_cache.get_resource(
			ProjectSettings.get_setting("escoria/ui/game_scene")
		).instance()
		

# Load settings
func _ready():
	settings = save_manager.load_settings()
	_on_settings_loaded(settings)
	inputs_manager.register_core()
	if ProjectSettings.get_setting("escoria/main/game_start_script").empty():
		logger.report_errors("escoria.gd", 
		[
			"Project setting 'escoria/main/game_start_script' is not set!"
		])
	start_script = self.esc_compiler.load_esc_file(
		ProjectSettings.get_setting("escoria/main/game_start_script")
	)


# Called by Escoria's main_scene as very very first event EVER.
# Usually you'll want to show some logos animations before spawning the main
# menu in the escoria/main/game_start_script 's :init event
func init():
	run_event_from_script(start_script, "init")


# Called by Main menu "start new game"
func new_game():
	run_event_from_script(start_script, "newgame")


# Run a generic action
#
# #### Parameters
#
# - action: type of the action to run
# - params: Parameters for the action
# - can_interrupt: if true, this command will interrupt any ongoing event 
# before it is finished
func do(action: String, params: Array = [], can_interrupt: bool = false) -> void:
	if current_state == GAME_STATE.DEFAULT:
		match action:
			"walk":
				if can_interrupt:
					event_manager.interrupt_running_event()
					
				self.action_manager.clear_current_action()
				
				var walk_fast = false
				if params.size() > 2:
					walk_fast = true if params[2] else false
					
				# Check moving object.
				if not escoria.object_manager.has(params[0]):
					escoria.logger.report_errors(
						"escoria.gd:do()",
						[
							"Walk action requested on inexisting " + \
							"object: %s " % params[0]
						]
					)
					return
				
				var moving_obj = escoria.object_manager.get_object(params[0])
				var target
				
				if params[1] is String:
					if not escoria.object_manager.has(params[1]):
						escoria.logger.report_errors(
							"escoria.gd:do()",
							[
								"Walk action requested to inexisting " + \
								"object: %s " % params[1]
							]
						)
						return
						
					target = escoria.object_manager.get_object(params[1])
				elif params[1] is Vector2:
					target = params[1]
				
				self.controller.perform_walk(moving_obj, target, walk_fast)
						
			"item_left_click":
				if params[0] is String:
					self.logger.info(
						"escoria.do(): item_left_click on item ", 
						[params[0]]
					)
					
					if can_interrupt:
						event_manager.interrupt_running_event()
					
					var item = self.object_manager.get_object(params[0])
					self.controller.perform_inputevent_on_object(item, params[1])
					
			"item_right_click":
				if params[0] is String:
					self.logger.info(
						"escoria.do(): item_right_click on item ", 
						[params[0]]
					)
					
					if can_interrupt:
						event_manager.interrupt_running_event()
						
					var item = self.object_manager.get_object(params[0])
					self.controller.perform_inputevent_on_object(item, params[1], true)
			
			"trigger_in":
				var trigger_id = params[0]
				var object_id = params[1]
				var trigger_in_verb = params[2]
				self.logger.info("escoria.do(): trigger_in %s by %s" % [
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
				self.logger.info("escoria.do(): trigger_out %s by %s" % [
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



# Apply the loaded settings
#
# #### Parameters
#
# * p_settings: Loaded settings
func _on_settings_loaded(p_settings: ESCSaveSettings) -> void:
	logger.info("******* settings loaded")
	if p_settings != null:
		settings = p_settings
	else:
		settings = ESCSaveSettings.new()

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
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Speech"), 
		linear2db(settings.speech_volume)
	)
	TranslationServer.set_locale(settings.text_lang)


# Input function to manage specific input keys
func _input(event):
	if event.is_action_pressed("esc_show_debug_prompt"):
		escoria.main.get_node("layers/debug_layer/esc_prompt_popup").popup()
	
	if event.is_action_pressed("ui_cancel"):
		emit_signal("request_pause_menu")
	
	if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
		if escoria.main.current_scene and escoria.main.current_scene.game:
			if event is InputEventMouseMotion:
				escoria.main.current_scene.game. \
					update_tooltip_following_mouse_position(event.position)


# Pauses or unpause the game
#
# #### Parameters
# - p_paused: if true, pauses the game. If false, unpauses the game.
func set_game_paused(p_paused: bool):
	get_tree().paused = p_paused


# Runs the event "event_name" from the "script" ESC script.
#
# #### Parameters
# - script: ESC script containing the event to run. The script must have been 
# loaded.
# - event_name: Name of the event to run
func run_event_from_script(script: ESCScript, event_name: String):
	if script == null:
		logger.report_errors(
			"escoria.gd:run_event_from_script()", 
			["Requested action %s on unloaded script %s" % [event_name, script],
			"Please load the ESC script using esc_compiler.load_esc_file()."]
		)
	event_manager.queue_event(script.events[event_name])
	var rc = yield(event_manager, "event_finished")
	while rc[1] != event_name:
		rc = yield(event_manager, "event_finished")

	if rc[0] != ESCExecution.RC_OK:
		self.logger.report_errors(
			"Start event of the start script returned unsuccessful: %d" % rc[0],
			[]
		)
		return
