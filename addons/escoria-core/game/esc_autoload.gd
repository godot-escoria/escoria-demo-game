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
	WAIT,
	LOADING,
	PAUSED
}


# Audio bus indices.
const BUS_MASTER = "Master"
const BUS_SFX = "SFX"
const BUS_MUSIC = "Music"
const BUS_SPEECH = "Speech"

# Path to camera scene
const CAMERA_SCENE_PATH = "res://addons/escoria-core/game/scenes/camera_player/camera.tscn"


# Logger class
const EscLogger = preload("res://addons/escoria-core/tools/logging/esc_logger.gd")

# Group for ESCItem's that can be collided with in a scene. Used for quick
# retrieval of such nodes to easily change their attributes at the same time.
const GROUP_ITEM_CAN_COLLIDE = "item_can_collide"

# Group for ESCItem's that are triggers
const GROUP_ITEM_TRIGGERS = "item_triggers"


# Logger instance
var logger = EscLogger.ESCLoggerFile.new()

# ESC Compiler
var esc_compiler = ESCCompiler.new()

# ESC Object Manager
var object_manager = ESCObjectManager.new()

# ESC Room Manager
var room_manager = ESCRoomManager.new()

# ESC Dependency Injector
var di = ESCDependencyInjector.new()

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

# Manager of game settings (resolution, sound, etc)
var settings_manager: ESCSettingsManager

# Resource cache handler
var resource_cache: ESCResourceCache

# Dialog player instantiator. This instance is called directly for dialogs.
var dialog_player: ESCDialogPlayer

# ESCScript interpreter factory
var interpreter_factory: ESCInterpreterFactory

# Inventory scene
var inventory

# The main scene
var main

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

# The "fallback" script to use when an action is tried on an item that hasn't
# been explicitly scripted.
var action_default_script: ESCScript

# Whether we ran a room directly from editor, not a full game
var is_direct_room_run: bool = false

# Whether we're quitting the game
var is_quitting: bool = false

# Whether we're creating a new game
var creating_new_game: bool = false
var temp: int = 0

# The game resolution
@onready var game_size = Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height"))

# The current state of the game
@onready var current_state = GAME_STATE.DEFAULT


# Ready function
func _ready():
	# We check if we run the full game or a room scene directly
	if not get_tree().current_scene is ESCMain:
		# Running a room scene. We need to instantiate the main scene ourselves
		# so that the Escoria scene is created and managers are instanced as well.
		is_direct_room_run = true
		var main_scene = preload("res://addons/escoria-core/game/main_scene.tscn").instantiate()
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
		paused.emit()
	else:
		resumed.emit()

	var scene_tree = get_tree()

	if is_instance_valid(scene_tree):
		scene_tree.paused = p_paused


# Called from main menu's "new game" button
func new_game():
	get_escoria().new_game()


# Called from main menu's "quit" button
func quit():
	is_quitting = true
	get_escoria().quit()
