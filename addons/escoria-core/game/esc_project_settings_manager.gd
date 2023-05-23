# Registers and allows access to Escoria-specific project settings.
extends Resource
class_name ESCProjectSettingsManager


# Root for Escoria-specific project settings
const _ESCORIA_SETTINGS_ROOT = "escoria"

# UI-related Escoria project settings
const _UI_ROOT = "ui"

const DEFAULT_DIALOG_TYPE = "%s/%s/default_dialog_type" % [_ESCORIA_SETTINGS_ROOT, _UI_ROOT]
const DEFAULT_TRANSITION = "%s/%s/default_transition" % [_ESCORIA_SETTINGS_ROOT, _UI_ROOT]
const DIALOG_MANAGERS = "%s/%s/dialog_managers" % [_ESCORIA_SETTINGS_ROOT, _UI_ROOT]
const GAME_SCENE = "%s/%s/game_scene" % [_ESCORIA_SETTINGS_ROOT, _UI_ROOT]
const INVENTORY_ITEM_SIZE = "%s/%s/inventory_item_size" % [_ESCORIA_SETTINGS_ROOT, _UI_ROOT]
const INVENTORY_ITEMS_PATH = "%s/%s/inventory_items_path" % [_ESCORIA_SETTINGS_ROOT, _UI_ROOT]
const TRANSITION_PATHS = "%s/%s/transition_paths" % [_ESCORIA_SETTINGS_ROOT, _UI_ROOT]


# Main Escoria project settings
const _MAIN_ROOT = "main"

const COMMAND_DIRECTORIES = "%s/%s/command_directories" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const FORCE_QUIT = "%s/%s/force_quit" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const GAME_MIGRATION_PATH = "%s/%s/game_migration_path" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const GAME_VERSION = "%s/%s/game_version" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const GAME_START_SCRIPT = "%s/%s/game_start_script" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const ACTION_DEFAULT_SCRIPT = "%s/%s/action_default_script" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const SAVEGAMES_PATH = "%s/%s/savegames_path" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const SETTINGS_PATH = "%s/%s/settings_path" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const TEXT_LANG = "%s/%s/text_lang" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]
const VOICE_LANG = "%s/%s/voice_lang" % [_ESCORIA_SETTINGS_ROOT, _MAIN_ROOT]

# Debug-related Escoria project settings
const _DEBUG_ROOT = "debug"

const CRASH_MESSAGE = "%s/%s/crash_message" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]
const DEVELOPMENT_LANG = "%s/%s/development_lang" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]
# If enabled, displays the room selection box for quick room change
const ENABLE_ROOM_SELECTOR = "%s/%s/enable_room_selector" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]
const LOG_FILE_PATH = "%s/%s/log_file_path" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]
const LOG_LEVEL = "%s/%s/log_level" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]
const ROOM_SELECTOR_ROOM_DIR = "%s/%s/room_selector_room_dir" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]
const TERMINATE_ON_ERRORS = "%s/%s/terminate_on_errors" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]
const TERMINATE_ON_WARNINGS = "%s/%s/terminate_on_warnings" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]
# If enabled, displays the hover stack on screen
const ENABLE_HOVER_STACK_VIEWER = "%s/%s/enable_hover_stack_viewer" % [_ESCORIA_SETTINGS_ROOT, _DEBUG_ROOT]

# Sound-related Escoria project settings
const _SOUND_ROOT = "sound"

const MASTER_VOLUME = "%s/%s/master_volume" % [_ESCORIA_SETTINGS_ROOT, _SOUND_ROOT]
const MUSIC_VOLUME = "%s/%s/music_volume" % [_ESCORIA_SETTINGS_ROOT, _SOUND_ROOT]
const SFX_VOLUME = "%s/%s/sfx_volume" % [_ESCORIA_SETTINGS_ROOT, _SOUND_ROOT]
const SPEECH_ENABLED = "%s/%s/speech_enabled" % [_ESCORIA_SETTINGS_ROOT, _SOUND_ROOT]
const SPEECH_EXTENSION = "%s/%s/speech_extension" % [_ESCORIA_SETTINGS_ROOT, _SOUND_ROOT]
const SPEECH_FOLDER = "%s/%s/speech_folder" % [_ESCORIA_SETTINGS_ROOT, _SOUND_ROOT]
const SPEECH_VOLUME = "%s/%s/speech_volume" % [_ESCORIA_SETTINGS_ROOT, _SOUND_ROOT]

# Platform-related Escoria project settings
const _PLATFORM_ROOT = "platform"

const SKIP_CACHE = "%s/%s/skip_cache" % [_ESCORIA_SETTINGS_ROOT, _PLATFORM_ROOT]
const SKIP_CACHE_MOBILE = "%s/%s/skip_cache.mobile" % [_ESCORIA_SETTINGS_ROOT, _PLATFORM_ROOT]

# Godot Windows project settings
const DISPLAY = "display"
const WINDOW = "window"
const SIZE = "size"
const FULLSCREEN = "%s/%s/%s/fullscreen" % [DISPLAY, WINDOW, SIZE]


# Register a new project setting if it hasn't been defined already
#
# #### Parameters
#
# - name: Name of the project setting
# - default_value: Default value
# - info: Property info for the setting
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


# Removes the specified project setting.
#
# #### Parameters
#
# - name: Name of the project setting
static func remove_setting(name: String) -> void:
	if not ProjectSettings.has_setting(name):
		push_error("Cannot remove project setting %s - it does not exist." % name)
		assert(false)
	ProjectSettings.set_setting(
			name,
			null
		)


# Retrieves the specified project setting.
#
# #### Parameters
#
# - key: Project setting name.
#
# *Returns* the value of the project setting located with key.
static func get_setting(key: String):
	if not ProjectSettings.has_setting(key):
		push_error("Parameter %s is not set!" % key)
		assert(false)

	return ProjectSettings.get_setting(key)


# Sets the specified project setting to the provided value.
#
# #### Parameters
#
# - key: Project setting name.
# - value: Project setting value.
static func set_setting(key: String, value) -> void:
	ProjectSettings.set_setting(key, value)


# Simple wrapper for consistency's sake.
#
# #### Parameters
#
# - key: Project setting name.
#
# *Returns* true iff the project setting exists.
static func has_setting(key: String) -> bool:
	return ProjectSettings.has_setting(key)
