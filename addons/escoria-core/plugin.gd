# Plugin script to initialize Escoria
tool
extends EditorPlugin

# The warning popup displayed on escoria-core enabling.
var popup_info: AcceptDialog


# Virtual function called when plugin is enabled.
func enable_plugin():
	add_autoload_singleton(
		"escoria",
		"res://addons/escoria-core/game/esc_autoload.gd"
	)
	# Prepare settings
	set_escoria_main_settings()
	set_escoria_debug_settings()
	set_escoria_ui_settings()
	set_escoria_sound_settings()
	set_escoria_platform_settings()

	# Add input actions in InputMap
#	if not InputMap.has_action(ESCInputsManager.SWITCH_ACTION_VERB):
#		InputMap.add_action(ESCInputsManager.SWITCH_ACTION_VERB)
#	if not InputMap.has_action(ESCInputsManager.ESC_SHOW_DEBUG_PROMPT):
#		InputMap.add_action(ESCInputsManager.ESC_SHOW_DEBUG_PROMPT)

	# Define standard settings
	ProjectSettings.set_setting(
		"application/run/main_scene",
		"res://addons/escoria-core/game/main_scene.tscn"
	)

	ProjectSettings.set_setting(
		"audio/default_bus_layout",
		"res://addons/escoria-core/default_bus_layout.tres"
	)

	popup_info = AcceptDialog.new()
	popup_info.dialog_text = """You enabled escoria-core plugin.

	Please ignore error messages in Output console and reload your project using
	Godot editor's "Project / Reload Current Project" menu.
	"""
	popup_info.connect("confirmed", self, "_on_warning_popup_confirmed", [], CONNECT_ONESHOT)
	get_editor_interface().get_editor_viewport().add_child(popup_info)
	popup_info.popup_centered()


func _on_warning_popup_confirmed():
	popup_info.queue_free()


# Virtual function called when plugin is disabled.
func disable_plugin():
	remove_autoload_singleton("escoria")
#	if InputMap.has_action(ESCInputsManager.SWITCH_ACTION_VERB):
#		InputMap.erase_action(ESCInputsManager.SWITCH_ACTION_VERB)
#	if InputMap.has_action(ESCInputsManager.SWITCH_ACTION_VERB):
#		InputMap.erase_action(ESCInputsManager.SWITCH_ACTION_VERB)


# Setup Escoria
func _enter_tree():
	pass


# Prepare the settings in the Escoria UI category
func set_escoria_ui_settings():
	register_setting(
		ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE,
		"",
		{
			"type": TYPE_STRING
		}
	)
	print("DEFAULT DIALOG TYPE RESET !!!")

	register_setting(
		ESCProjectSettingsManager.GAME_SCENE,
		"",
		{
			"name": ESCProjectSettingsManager.GAME_SCENE,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn, *.scn"
		}
	)

	register_setting(
		ESCProjectSettingsManager.INVENTORY_ITEMS_PATH,
		"res://game/items/inventory/",
		{
			"name": ESCProjectSettingsManager.INVENTORY_ITEMS_PATH,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	register_setting(
		ESCProjectSettingsManager.DEFAULT_TRANSITION,
		"curtain",
		{
			"name": ESCProjectSettingsManager.DEFAULT_TRANSITION,
			"type": TYPE_STRING
		}
	)

	register_setting(
		ESCProjectSettingsManager.TRANSITION_PATHS,
		[
			"res://addons/escoria-core/game/scenes/transitions/shaders/"
		],
		{
			"name": ESCProjectSettingsManager.TRANSITION_PATHS,
			"type": TYPE_STRING_ARRAY,
			"hint": PROPERTY_HINT_DIR
		}
	)

	register_setting(
		ESCProjectSettingsManager.INVENTORY_ITEM_SIZE,
		Vector2(72, 72),
		{
			"name": ESCProjectSettingsManager.INVENTORY_ITEM_SIZE,
			"type": TYPE_VECTOR2
		}
	)

	register_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS,
		[],
		{
			"type": TYPE_STRING_ARRAY
		}
	)


# Prepare the settings in the Escoria main category
func set_escoria_main_settings():
	register_setting(
		ESCProjectSettingsManager.GAME_VERSION,
		"",
		{
			"type": TYPE_STRING
		}
	)

	register_setting(
		ESCProjectSettingsManager.GAME_START_SCRIPT,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.esc"
		}
	)

	register_setting(
		ESCProjectSettingsManager.FORCE_QUIT,
		true,
		{
			"type": TYPE_BOOL
		}
	)

	register_setting(
		ESCProjectSettingsManager.COMMAND_DIRECTORIES,
		[
			"res://addons/escoria-core/game/core-scripts/esc/commands"
		],
		{
			"type": TYPE_ARRAY,
		}
	)

	register_setting(
		ESCProjectSettingsManager.TEXT_LANG,
		TranslationServer.get_locale(),
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE
		}
	)

	register_setting(
		ESCProjectSettingsManager.VOICE_LANG,
		TranslationServer.get_locale(),
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE
		}
	)

	register_setting(
		ESCProjectSettingsManager.SAVEGAMES_PATH,
		"user://saves/",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	register_setting(
		ESCProjectSettingsManager.SETTINGS_PATH,
		"user://",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	register_setting(
		ESCProjectSettingsManager.GAME_MIGRATION_PATH,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)


# Prepare the settings in the Escoria debug category
func set_escoria_debug_settings():
	register_setting(
		ESCProjectSettingsManager.TERMINATE_ON_WARNINGS,
		false,
		{
			"type": TYPE_BOOL
		}
	)

	register_setting(
		ESCProjectSettingsManager.TERMINATE_ON_ERRORS,
		true,
		{
			"type": TYPE_BOOL
		}
	)

	register_setting(
		ESCProjectSettingsManager.DEVELOPMENT_LANG,
		"en",
		{
			"type": TYPE_STRING
		}
	)

	register_setting(
		ESCProjectSettingsManager.LOG_LEVEL,
		"ERROR",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "ERROR,WARNING,INFO,DEBUG,TRACE"
		}
	)

	register_setting(
		ESCProjectSettingsManager.LOG_FILE_PATH,
		"user://",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	register_setting(
		ESCProjectSettingsManager.CRASH_MESSAGE,
		"We're sorry, but the game crashed. Please send us the " +
		"following files:\n\n%s",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT
		}
	)

	register_setting(
		ESCProjectSettingsManager.ENABLE_ROOM_SELECTOR,
		false,
		{
			"type": TYPE_BOOL
		}
	)

	register_setting(
		ESCProjectSettingsManager.ROOM_SELECTOR_ROOM_DIR,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)


# Prepare the settings in the Escoria sound settings
func set_escoria_sound_settings():
	register_setting(
		ESCProjectSettingsManager.MASTER_VOLUME,
		1,
		{
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	register_setting(
		ESCProjectSettingsManager.MUSIC_VOLUME,
		1,
		{
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	register_setting(
		ESCProjectSettingsManager.SFX_VOLUME,
		1,
		{
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	register_setting(
		ESCProjectSettingsManager.SPEECH_VOLUME,
		1,
		{
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	register_setting(
		ESCProjectSettingsManager.SPEECH_ENABLED,
		true,
		{
			"type": TYPE_BOOL
		}
	)

	register_setting(
		ESCProjectSettingsManager.SPEECH_FOLDER,
		"res://speech",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	register_setting(
		ESCProjectSettingsManager.SPEECH_EXTENSION,
		"ogg",
		{
			"type": TYPE_STRING
		}
	)


# Prepare the settings in the Escoria platform category and may need special
# setting per build
func set_escoria_platform_settings():
	# Skip cache - certain platforms (esp. mobile) lack memory for caching
	# scenes.
	# If set to true, all generic scenes (UI, inventory, etc) will be loaded
	# as any other scene.
	register_setting(
		ESCProjectSettingsManager.SKIP_CACHE,
		false,
		{
			"type": TYPE_BOOL
		}
	)

	register_setting(
		ESCProjectSettingsManager.SKIP_CACHE_MOBILE,
		true,
		{
			"type": TYPE_BOOL
		}
	)


# Register a new project setting if it hasn't been defined already
#
# #### Parameters
#
# - name: Name of the project setting
# - default: Default value
# - info: Property info for the setting
static func register_setting(name: String, default, info: Dictionary) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(
			name,
			default
		)
		info.name = name
		ProjectSettings.add_property_info(info)
