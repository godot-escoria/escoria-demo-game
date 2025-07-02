## Registers and allows access to Escoria-specific project settings.
## Registers and allows access to Escoria-specific project settings.[br]
extends Resource
class_name ESCProjectSettingsManager

## Root for Escoria-specific project settings.
const _ESCORIA_SETTINGS_ROOT = "escoria"

## UI-related Escoria project settings.
const _UI_ROOT = "ui"

## Path to the default dialog type setting.
const DEFAULT_DIALOG_TYPE = _ESCORIA_SETTINGS_ROOT + "/" + _UI_ROOT + "/" + "default_dialog_type"
## Path to the default transition setting.
const DEFAULT_TRANSITION = _ESCORIA_SETTINGS_ROOT + "/" + _UI_ROOT + "/" + "default_transition"
## Path to the dialog managers setting.
const DIALOG_MANAGERS = _ESCORIA_SETTINGS_ROOT + "/" + _UI_ROOT + "/" + "dialog_managers"
## Path to the game scene setting.
const GAME_SCENE = _ESCORIA_SETTINGS_ROOT + "/" + _UI_ROOT + "/" + "game_scene"
## Path to the inventory item size setting.
const INVENTORY_ITEM_SIZE = _ESCORIA_SETTINGS_ROOT + "/" + _UI_ROOT + "/" + "inventory_item_size"
## Path to the inventory items path setting.
const INVENTORY_ITEMS_PATH = _ESCORIA_SETTINGS_ROOT + "/" + _UI_ROOT + "/" + "inventory_items_path"
## Path to the transition paths setting.
const TRANSITION_PATHS = _ESCORIA_SETTINGS_ROOT + "/" + _UI_ROOT + "/" + "transition_paths"

## Main Escoria project settings root.
const _MAIN_ROOT = "main"

## Path to the command directories setting.
const COMMAND_DIRECTORIES = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "command_directories"
## Path to the force quit setting.
const FORCE_QUIT = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "force_quit"
## Path to the game migration path setting.
const GAME_MIGRATION_PATH = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "game_migration_path"
## Path to the game version setting.
const GAME_VERSION = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "game_version"
## Path to the game start script setting.
const GAME_START_SCRIPT = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "game_start_script"
## Path to the action default script setting.
const ACTION_DEFAULT_SCRIPT = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "action_default_script"
## Path to the savegames path setting.
const SAVEGAMES_PATH = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "savegames_path"
## Path to the settings path setting.
const SETTINGS_PATH = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "settings_path"
## Path to the text language setting.
const TEXT_LANG = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "text_lang"
## Path to the voice language setting.
const VOICE_LANG = _ESCORIA_SETTINGS_ROOT + "/" + _MAIN_ROOT + "/" + "voice_lang"

## Debug-related Escoria project settings root.
const _DEBUG_ROOT = "debug"

## Path to the crash message setting.
const CRASH_MESSAGE = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "crash_message"
## Path to the development language setting.
const DEVELOPMENT_LANG = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "development_lang"
## If enabled, displays the room selection box for quick room change.
const ENABLE_ROOM_SELECTOR = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "enable_room_selector"
## Path to the log file path setting.
const LOG_FILE_PATH = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "log_file_path"
## Path to the log level setting.
const LOG_LEVEL = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "log_level"
## Path to the room selector room directory setting.
const ROOM_SELECTOR_ROOM_DIR = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "room_selector_room_dir"
## Path to the terminate on errors setting.
const TERMINATE_ON_ERRORS = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "terminate_on_errors"
## Path to the terminate on warnings setting.
const TERMINATE_ON_WARNINGS = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "terminate_on_warnings"
## If enabled, displays the hover stack on screen.
const ENABLE_HOVER_STACK_VIEWER = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "enable_hover_stack_viewer"
## If enabled, performs script analysis at runtime.
const PERFORM_SCRIPT_ANALYSIS_AT_RUNTIME = _ESCORIA_SETTINGS_ROOT + "/" + _DEBUG_ROOT + "/" + "perform_script_analysis_at_runtime"

## Sound-related Escoria project settings root.
const _SOUND_ROOT = "sound"

## Path to the master volume setting.
const MASTER_VOLUME = _ESCORIA_SETTINGS_ROOT + "/" + _SOUND_ROOT + "/" + "master_volume"
## Path to the music volume setting.
const MUSIC_VOLUME = _ESCORIA_SETTINGS_ROOT + "/" + _SOUND_ROOT + "/" + "music_volume"
## Path to the sfx volume setting.
const SFX_VOLUME = _ESCORIA_SETTINGS_ROOT + "/" + _SOUND_ROOT + "/" + "sfx_volume"
## Path to the speech enabled setting.
const SPEECH_ENABLED = _ESCORIA_SETTINGS_ROOT + "/" + _SOUND_ROOT + "/" + "speech_enabled"
## Path to the speech extension setting.
const SPEECH_EXTENSION = _ESCORIA_SETTINGS_ROOT + "/" + _SOUND_ROOT + "/" + "speech_extension"
## Path to the speech folder setting.
const SPEECH_FOLDER = _ESCORIA_SETTINGS_ROOT + "/" + _SOUND_ROOT + "/" + "speech_folder"
## Path to the speech volume setting.
const SPEECH_VOLUME = _ESCORIA_SETTINGS_ROOT + "/" + _SOUND_ROOT + "/" + "speech_volume"

## Platform-related Escoria project settings root.
const _PLATFORM_ROOT = "platform"

## Path to the skip cache setting.
const SKIP_CACHE = _ESCORIA_SETTINGS_ROOT + "/" + _PLATFORM_ROOT + "/" + "skip_cache"
## Path to the skip cache mobile setting.
const SKIP_CACHE_MOBILE = _ESCORIA_SETTINGS_ROOT + "/" + _PLATFORM_ROOT + "/" + "skip_cache.mobile"

## Godot Windows project settings root.
const DISPLAY = "display"
const WINDOW = "window"
const SIZE = "size"
## Path to the window mode setting.
const WINDOW_MODE = DISPLAY + "/" + WINDOW + "/" + SIZE + "/" + "mode"
## Path to the fullscreen setting.
const FULLSCREEN = DISPLAY + "/" + WINDOW + "/" + SIZE + "/" + "fullscreen"

## Register a new project setting if it hasn't been defined already.[br]
## [br]
## #### Parameters[br]
## [br]
## - name: Name of the project setting[br]
## - default_value: Default value[br]
## - info: Property info for the setting
static func register_setting(name: String, default_value, info: Dictionary) -> void:
	if default_value == null:
		push_error("Default_value cannot be null. Use remove_setting function to remove settings.")
		assert(false)

	ProjectSettings.set_setting(
		name,
		default_value
	)
	if default_value != null:
		info.name = name

		# Project settings require a "type" to be set
		if not "type" in info:
			info.type=typeof(default_value)
		ProjectSettings.add_property_info(info)


## Removes the specified project setting.[br]
## [br]
## #### Parameters[br]
## [br]
## - name: Name of the project setting
static func remove_setting(name: String) -> void:
	if not ProjectSettings.has_setting(name):
		push_error("Cannot remove project setting %s - it does not exist." % name)
		assert(false)
	ProjectSettings.set_setting(
			name,
			null
		)


## Retrieves the specified project setting.[br]
## [br]
## #### Parameters[br]
## [br]
## - key: Project setting name.[br]
## [br]
## *Returns* The value of the project setting located with key
static func get_setting(key: String):
	if not ProjectSettings.has_setting(key):
		push_error("Parameter %s is not set!" % key)
		assert(false)
	return ProjectSettings.get_setting(key)


## Sets the specified project setting to the provided value.[br]
## [br]
## #### Parameters[br]
## [br]
## - key: Project setting name.[br]
## - value: Project setting value
static func set_setting(key: String, value) -> void:
	ProjectSettings.set_setting(key, value)


## Simple wrapper for consistency's sake.[br]
## [br]
## #### Parameters[br]
## [br]
## - key: Project setting name.[br]
## [br]
## *Returns* True iff the project setting exists
static func has_setting(key: String) -> bool:
	return ProjectSettings.has_setting(key)
