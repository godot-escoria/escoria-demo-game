extends Node
## This is Escoria's singleton script.
## It holds accessors to some utils, such as Escoria's logger.

## Signal sent when Escoria is paused
signal paused

## Signal sent when Escoria is resumed from pause
signal resumed


## Current game state
## * DEFAULT: Common game function
## * DIALOG: Game is playing a dialog
## * WAIT: Game is waiting
## * LOADING: Game is currently loading
enum GAME_STATE {
	DEFAULT,
	DIALOG,
	WAIT,
	LOADING
}


## Master audio bus
const BUS_MASTER = "Master"

## SFX audio bus
const BUS_SFX = "SFX"

## Music audio bus
const BUS_MUSIC = "Music"

## Speech audio bus
const BUS_SPEECH = "Speech"

## Logger class
const Logger = preload("res://addons/escoria-core/tools/logging/esc_logger.gd")

## Group for ESCItem's that can be collided with in a scene. Used for quick[br]
## retrieval of such nodes to easily change their attributes at the same time.
const GROUP_ITEM_CAN_COLLIDE = "item_can_collide"

## Group for ESCItem's that are triggers
const GROUP_ITEM_TRIGGERS = "item_triggers"


## Logger instance
var logger = Logger.ESCLoggerFile.new()

## ESC Compiler instance
var esc_compiler = ESCCompiler.new()

## ESC Object Manager instance
var object_manager = ESCObjectManager.new()

## ESC Room Manager instance
var room_manager = ESCRoomManager.new()

## Inventory manager instance
var inventory_manager: ESCInventoryManager

## Action manager instance
var action_manager: ESCActionManager

## Event manager instance
var event_manager: ESCEventManager

## Globals registry instance
var globals_manager: ESCGlobalsManager

## ASHES command registry instance
var command_registry: ESCCommandRegistry

## Manager of game settings (resolution, sound, etc)
var settings_manager: ESCSettingsManager

## Resource cache handler
var resource_cache: ESCResourceCache

## Dialog player instantiator. This instance is called directly for dialogs.
var dialog_player: ESCDialogPlayer

## ESCScript interpreter factory instance
var interpreter_factory: ESCInterpreterFactory

## Inputs manager instance
var inputs_manager: ESCInputsManager

## Savegames and settings manager
var save_manager: ESCSaveManager

## The game scene loaded
var game_scene: ESCGame

## The main player camera
var player_camera: ESCCamera

## The compiled start script loaded from ProjectSettings
## escoria/main/game_start_script
var start_script: ESCScript

## The "fallback" script to use when an action is tried on an item that hasn't
## been explicitly scripted.
var action_default_script: ESCScript

## Whether we ran a room directly from editor, not a full game
var is_direct_room_run: bool = false

## Whether we're quitting the game
var is_quitting: bool = false

## Terrain of the current room
var room_terrain

## Inventory scene
var inventory

## The main scene
var main

## Whether Escoria is creating a new game
var creating_new_game: bool = false
#var temp: int = 0

## Game actual resolution obtained from viewport.
@onready var game_size = get_viewport().size

## Current state of Escoria (GAME_STATE enum) 
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


## Get the Escoria node. That node gives access to the Escoria scene that's[br]
## instanced by the main_scene (if full game is run) or by this autoload if[br]
## room is run directly.
func get_escoria():
	# We check if we run the full game or a room scene directly
	if get_tree().current_scene is ESCMain:
		return get_node("/root/main_scene").escoria_node
	else:
		return get_node("main_scene").escoria_node


## Pauses or unpause the game[br]
##[br]
## #### Parameters[br]
## - p_paused: if true, pauses the game. If false, unpauses the game.
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
