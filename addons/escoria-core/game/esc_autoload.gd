# This is Escoria's singleton script.
# It holds accessors to some utils, such as Escoria's logger.

extends Node


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

# Path to camera scene
const CAMERA_SCENE_PATH = "res://addons/escoria-core/game/scenes/camera_player/camera.tscn"


# Logger
const Logger = preload("res://addons/escoria-core/game/esc_logger.gd")
var logger = Logger.ESCLoggerFile.new()

# ESC Compiler
var esc_compiler = ESCCompiler.new()

# ESC Object Manager
var object_manager = ESCObjectManager.new()

# ESC Room Manager 
var room_manager = ESCRoomManager.new()

# Terrain of the current room
var room_terrain

# The inventory manager instance
var inventory_manager: ESCInventoryManager

# The action manager instance
var action_manager: ESCActionManager

# ESC Event manager instance
var event_manager: ESCEventManager

# ESC globals registry instance
var globals_manager: ESCGlobalsManager

# ESC command registry instance
var command_registry: ESCCommandRegistry

# Resource cache handler
var resource_cache: ESCResourceCache

# Dialog player instantiator. This instance is called directly for dialogs.
var dialog_player: ESCDialogPlayer

# Inventory scene
var inventory

# These are settings that the player can affect and save/load later
var settings: ESCSaveSettings

# The game resolution
var game_size

# The main scene
var main

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

# Whether we ran a room directly from editor, not a full game
var is_direct_room_run: bool = false

# Ready function
func _ready():
	# We check if we run the full game or a room scene directly
	if not get_tree().current_scene is ESCMain:
		# Running a room scene. We need to instantiate the main scene ourselves
		# so that the Escoria scene is created and managers are instanced as well.
		is_direct_room_run = true
		var main_scene = preload("res://addons/escoria-core/game/main_scene.tscn").instance()
		add_child(main_scene)


# Get the Escoria node. That node gives access to the Escoria scene that's
# instanced by the main_scene (if full game is run) or by this autoload if
# room is run directly.
func get_escoria():
	# We check if we run the full game or a room scene directly
	if get_tree().current_scene is ESCMain:
		return get_node("/root/main_scene").escoria_node
	else:
		return get_node("main_scene").escoria_node


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


# Apply the loaded settings
#
# #### Parameters
#
# * p_settings: Loaded settings
func apply_settings(p_settings: ESCSaveSettings) -> void:
	if not Engine.is_editor_hint():
		escoria.logger.info(self, "******* settings loaded")
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


# Called from main menu's "new game" button
func new_game():
	get_escoria().new_game()


# Called from main menu's "quit" button
func quit():
	get_escoria().quit()

