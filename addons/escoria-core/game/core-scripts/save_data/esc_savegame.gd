## Resource used for holding savegames data.
extends Resource
class_name ESCSaveGame

## Access key for the main data last_scene_global_id.
const MAIN_LAST_SCENE_GLOBAL_ID_KEY = "last_scene_global_id"

## Access key for the main data current_scene_filename.
const MAIN_CURRENT_SCENE_FILENAME_KEY = "current_scene_filename"

## Escoria version which the savegame was created with.
@export var escoria_version: String

## Game version which the savegame was created with.
@export var game_version: String = ""

## Name of the savegame. Can be custom value, provided by the player.
@export var name: String = ""

## Date of creation of the savegame.
@export var date: Dictionary = {}

## Main data to be saved.
@export var main: Dictionary = {}

## Escoria Global variables exported from ESCGlobalsManager.
@export var globals: Dictionary = {}

## Inventory items.
@export var inventory: Array = []

## Escoria objects exported from ESCObjectsManager.
@export var objects: Dictionary = {}

## Running event exported from ESCEventManager.
@export var events: Dictionary = {}

## Enabled ESCTerrain navpolygons.
@export var terrain_navpolys: Dictionary = {}

## Settings.
@export var settings: Dictionary = {}

## Custom data.
@export var custom_data: Dictionary = {}
