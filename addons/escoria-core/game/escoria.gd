# The escoria main script
tool
extends Node

# Signal sent when pause menu has to be displayed
signal request_pause_menu

# Signal sent when Escoria is paused
signal paused

# Signal sent when Escoria is resumed from pause
signal resumed


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

# ESC room manager instance
var room_manager: ESCRoomManager

# ESC object manager instance
var object_manager: ESCObjectManager

# ESC command registry instance
var command_registry: ESCCommandRegistry

# Resource cache handler
var resource_cache: ESCResourceCache

# Terrain of the current room
var room_terrain

# Dialog player instantiator. This instance is called directly for dialogs.
var dialog_player: ESCDialogPlayer

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
	self.room_manager = ESCRoomManager.new()
	
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
	apply_settings(settings)
	room_manager.register_reserved_globals()
	inputs_manager.register_core()
	if ProjectSettings.get_setting("escoria/main/game_start_script").empty():
		logger.report_errors("escoria.gd", 
		[
			"Project setting 'escoria/main/game_start_script' is not set!"
		])
	start_script = self.esc_compiler.load_esc_file(
		ProjectSettings.get_setting("escoria/main/game_start_script")
	)


func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			escoria.logger.close_logs()
			get_tree().quit()
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			escoria.logger.close_logs()
			get_tree().quit()


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
				
				self.action_manager.perform_walk(moving_obj, target, walk_fast)
						
			"item_left_click":
				if params[0] is String:
					self.logger.info(
						"escoria.do(): item_left_click on item ", 
						[params[0]]
					)
					
					if can_interrupt:
						event_manager.interrupt_running_event()
					
					var item = self.object_manager.get_object(params[0])
					self.action_manager.perform_inputevent_on_object(item, params[1])
					
			"item_right_click":
				if params[0] is String:
					self.logger.info(
						"escoria.do(): item_right_click on item ", 
						[params[0]]
					)
					
					if can_interrupt:
						event_manager.interrupt_running_event()
						
					var item = self.object_manager.get_object(params[0])
					self.action_manager.perform_inputevent_on_object(item, params[1], true)
			
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
func apply_settings(p_settings: ESCSaveSettings) -> void:
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
	
	game_scene.apply_custom_settings(settings.custom_settings)


# Input function to manage specific input keys
func _input(event):
	if InputMap.has_action("esc_show_debug_prompt") \
			and event.is_action_pressed("esc_show_debug_prompt"):
		escoria.main.get_node("layers/debug_layer/esc_prompt_popup").popup()
	
	if event.is_action_pressed("ui_cancel"):
		emit_signal("request_pause_menu")
	

# Pauses or unpause the game
#
# #### Parameters
# - p_paused: if true, pauses the game. If false, unpauses the game.
func set_game_paused(p_paused: bool):
	if p_paused:
		emit_signal("paused")
	else:
		emit_signal("resumed")
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
		

# Register a new project setting if it hasn't been defined already
#
# #### Parameters
#
# - name: Name of the project setting
# - default: Default value
# - info: Property info for the setting
func register_setting(name: String, default, info: Dictionary):
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(
			name,
			default
		)
		info.name = name
		ProjectSettings.add_property_info(info)
		

# Register a user interface. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
func register_ui(game_scene: String):
	if not ProjectSettings.get_setting("escoria/ui/game_scene") in [
		"",
		game_scene
	]:
		logger.report_errors(
			"escoria.gd:register_ui()",
			[
				"Can't register user interface because %s is registered" % \
						ProjectSettings.get_setting("escoria/ui/game_scene")
			]
		)
	ProjectSettings.set_setting(
		"escoria/ui/game_scene",
		game_scene
	)
	

# Deregister a user interface
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
func deregister_ui(game_scene: String):
	if ProjectSettings.get_setting("escoria/ui/game_scene") != game_scene:
		logger.report_errors(
			"escoria.gd:deregister_ui()",
			[
				(
					"Can't deregister user interface %s because it " +
					"is not registered."
				) % ProjectSettings.get_setting("escoria/ui/game_scene")
			]
		)
	ProjectSettings.set_setting(
		"escoria/ui/game_scene",
		""
	)
	

# Register a dialog manager addon. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - manager_class: Path to the manager class script
func register_dialog_manager(manager_class: String):
	var dialog_managers: Array = ProjectSettings.get_setting(
		"escoria/ui/dialog_managers"
	)
	if manager_class in dialog_managers:
		return
	dialog_managers.push_back(manager_class)
	ProjectSettings.set_setting(
		"escoria/ui/dialog_managers",
		dialog_managers
	)
	

# Deregister a dialog manager addon
#
# #### Parameters
# - manager_class: Path to the manager class script
func deregister_dialog_manager(manager_class: String):
	var dialog_managers: Array = ProjectSettings.get_setting(
		"escoria/ui/dialog_managers"
	)
	if not manager_class in dialog_managers:
		logger.report_warnings(
			"escoria.gd:deregister_dialog_manager()",
			[
				"Dialog manager %s is not registered" % manager_class
			]
		)
		return
	
	dialog_managers.erase(manager_class)
	
	ProjectSettings.set_setting(
		"escoria/ui/dialog_managers",
		dialog_managers
	)


# Function called to quit the game.
func quit():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
