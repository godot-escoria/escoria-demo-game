# This is Escoria's singleton script.
# It holds accessors to some utils, such as Escoria's logger.

extends Node

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


##########################################################


# Current game state
# * DEFAULT: Common game function
# * DIALOG: Game is playing a dialog
# * WAIT: Game is waiting
enum GAME_STATE {
	DEFAULT,
	DIALOG,
	WAIT
}

const CAMERA_SCENE_PATH = "res://addons/escoria-core/game/scenes/camera_player/camera.tscn"

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


# Get the Escoria node. That node gives access to 
func get_escoria():
	return get_node("/root/main_scene").escoria_node


# Register a user interface. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
func register_ui(game_scene: String):
	var game_scene_setting_value = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_SCENE
	)

	if not game_scene_setting_value in [
		"",
		game_scene
	]:
		logger.error(
			self,
			"Can't register user interface because %s is registered"
					% game_scene_setting_value
		)
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.GAME_SCENE,
		game_scene
	)


# Deregister a user interface
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
func deregister_ui(game_scene: String):
	var game_scene_setting_value = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_SCENE
		)

	if game_scene_setting_value != game_scene:
		logger.error(
			"Can't deregister user interface %s because it is not registered."
					% game_scene_setting_value
		)
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.GAME_SCENE,
		""
	)


# Register a dialog manager addon. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - manager_class: Path to the manager class script
func register_dialog_manager(manager_class: String):
	var dialog_managers: Array = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	)

	if manager_class in dialog_managers:
		return

	dialog_managers.push_back(manager_class)

	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS,
		dialog_managers
	)


# Deregister a dialog manager addon
#
# #### Parameters
# - manager_class: Path to the manager class script
func deregister_dialog_manager(manager_class: String):
	var dialog_managers: Array = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	)

	if not manager_class in dialog_managers:
		logger.warn(
			self,
			"Dialog manager %s is not registered" % manager_class
		)
		return

	dialog_managers.erase(manager_class)

	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS,
		dialog_managers
	)
