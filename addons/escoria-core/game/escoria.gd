# The escoria main script
tool
extends Node
class_name Escoria


# Signal sent when Escoria is paused
signal paused

# Signal sent when Escoria is resumed from pause
signal resumed


# Current game state
# * DEFAULT: Common game function
# * DIALOG: Game is playing a dialog
# * WAIT: Game is waiting
enum GAME_STATE {
	DEFAULT,
	DIALOG,
	WAIT
}


# Audio bus indices.
const BUS_MASTER = "Master"
const BUS_SFX = "SFX"
const BUS_MUSIC = "Music"
const BUS_SPEECH = "Speech"

const CAMERA_SCENE_PATH = "res://addons/escoria-core/game/scenes/camera_player/camera.tscn"


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

# ESC project settings manager instance
var project_settings_manager: ESCProjectSettingsManager

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

# The game resolution
onready var game_size = get_viewport().size

# The main scene
onready var main = $main

# The current state of the game
onready var current_state = GAME_STATE.DEFAULT

# The escoria inputs manager
var inputs_manager: ESCInputsManager

# Savegames and settings manager
var save_manager: ESCSaveManager

# The game scene loaded
var game_scene: ESCGame

# The main player camera
var player_camera: ESCCamera

# The compiled start script loaded from ProjectSettings
# escoria/main/game_start_script
var start_script: ESCScript


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
	self.project_settings_manager = ESCProjectSettingsManager.new()

	settings = ESCSaveSettings.new()

	if self.project_settings_manager.get_setting(self.project_settings_manager.GAME_SCENE) == "":
		logger.report_errors("escoria.gd",
			["Project setting '%s' is not set!" % self.project_settings_manager.GAME_SCENE]
		)
	else:
		game_scene = resource_cache.get_resource(
			self.project_settings_manager.get_setting(self.project_settings_manager.GAME_SCENE)
		).instance()

	print("ESC {0}".format([get_script().get_path()]))


# Load settings
func _ready():
	_handle_direct_scene_run()

	settings = save_manager.load_settings()
	apply_settings(settings)
	room_manager.register_reserved_globals()
	inputs_manager.register_core()
	if self.project_settings_manager.get_setting(self.project_settings_manager.GAME_START_SCRIPT).empty():
		logger.report_errors("escoria.gd",
		[
			"Project setting '%s' is not set!" % self.project_settings_manager.GAME_START_SCRIPT
		])
	start_script = self.esc_compiler.load_esc_file(
		self.project_settings_manager.get_setting(self.project_settings_manager.GAME_START_SCRIPT)
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
	# Don't show the UI until we're ready in order to avoid a sometimes-noticeable
	# blink. The UI will be "shown" later via a visibility update to the first room.
	escoria.game_scene.escoria_hide_ui()
	run_event_from_script(start_script, self.event_manager.EVENT_INIT)


# Called by Main menu "start new game"
func new_game():
	run_event_from_script(start_script, self.event_manager.EVENT_NEW_GAME)


# Apply the loaded settings
#
# #### Parameters
#
# * p_settings: Loaded settings
func apply_settings(p_settings: ESCSaveSettings) -> void:
	if not Engine.is_editor_hint():
		logger.info("******* settings loaded")
		if p_settings != null:
			settings = p_settings
		else:
			settings = ESCSaveSettings.new()

		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(BUS_MASTER),
			linear2db(settings.master_volume)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(BUS_SFX),
			linear2db(settings.sfx_volume)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(BUS_MUSIC),
			linear2db(settings.music_volume)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(BUS_SPEECH),
			linear2db(settings.speech_volume)
		)
		TranslationServer.set_locale(settings.text_lang)

		game_scene.apply_custom_settings(settings.custom_settings)


# Input function to manage specific input keys
func _input(event):
	if InputMap.has_action(ESCInputsManager.ESC_SHOW_DEBUG_PROMPT) \
			and event.is_action_pressed(ESCInputsManager.ESC_SHOW_DEBUG_PROMPT):
		escoria.main.get_node("layers/debug_layer/esc_prompt_popup").popup()


# Pauses or unpause the game
#
# #### Parameters
# - p_paused: if true, pauses the game. If false, unpauses the game.
func set_game_paused(p_paused: bool):
	if p_paused:
		emit_signal("paused")
	else:
		emit_signal("resumed")

	var scene_tree = get_tree()

	if is_instance_valid(scene_tree):
		scene_tree.paused = p_paused


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


# Register a user interface. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
func register_ui(game_scene: String):
	var game_scene_setting_value = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.GAME_SCENE
	)

	if not game_scene_setting_value in [
		"",
		game_scene
	]:
		logger.report_errors(
			"escoria.gd:register_ui()",
			[
				"Can't register user interface because %s is registered" % \
					game_scene_setting_value
			]
		)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.GAME_SCENE,
		game_scene
	)


# Deregister a user interface
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
func deregister_ui(game_scene: String):
	var game_scene_setting_value = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.GAME_SCENE
		)

	if game_scene_setting_value != game_scene:
		logger.report_errors(
			"escoria.gd:deregister_ui()",
			[
				(
					"Can't deregister user interface %s because it " +
					"is not registered."
				) % game_scene_setting_value
			]
		)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.GAME_SCENE,
		""
	)


# Register a dialog manager addon. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - manager_class: Path to the manager class script
func register_dialog_manager(manager_class: String):
	var dialog_managers: Array = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.DIALOG_MANAGERS
	)

	if manager_class in dialog_managers:
		return

	dialog_managers.push_back(manager_class)

	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.DIALOG_MANAGERS,
		dialog_managers
	)


# Deregister a dialog manager addon
#
# #### Parameters
# - manager_class: Path to the manager class script
func deregister_dialog_manager(manager_class: String):
	var dialog_managers: Array = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.DIALOG_MANAGERS
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

	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.DIALOG_MANAGERS,
		dialog_managers
	)


# Function called to quit the game.
func quit():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)


# Handle anything necessary if the game started a scene directly.
func _handle_direct_scene_run() -> void:
	var current_scene_root: Node = get_tree().get_current_scene()

	if current_scene_root == null:
		# there's no 'current scene'
		# e.g. you're opening escoria.tscn from the editor
		return

	if current_scene_root.filename == ProjectSettings.get_setting('application/run/main_scene'):
		# This is a normal, full-game run, so there's nothing to do.
		return

	if current_scene_root is ESCRoom:
		escoria.object_manager.set_current_room(current_scene_root)


# Used by game.gd to determine whether the game scene is ready to take inputs
# from the _input() function. To do so, the current_scene must be set, the game
# scene must be set, and the game scene must've been notified that the room
# is ready.
#
# *Returns*
# true if game scene is ready for inputs
func is_ready_for_inputs() -> bool:
	return escoria.main.current_scene and escoria.main.current_scene.game \
			and escoria.main.current_scene.game.room_ready_for_inputs
