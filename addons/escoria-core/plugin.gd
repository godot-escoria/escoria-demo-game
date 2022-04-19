# Plugin script to initialize Escoria
tool
extends EditorPlugin


# Virtual function called when plugin is enabled.
func _enable_plugin():
	add_autoload_singleton(
		"escoria",
		"res://addons/escoria-core/game/escoria.tscn"
	)

	# Add input actions in InputMap
	InputMap.add_action(get_node("escoria").inputs_manager.SWITCH_ACTION_VERB)
	InputMap.add_action(get_node("escoria").inputs_manager.ESC_SHOW_DEBUG_PROMPT)

	# Define standard settings
	ProjectSettings.set_setting(
		"application/run/main_scene",
		"res://addons/escoria-core/game/main_scene.tscn"
	)

	ProjectSettings.set_setting(
		"audio/default_bus_layout",
		"res://addons/escoria-core/default_bus_layout.tres"
	)


# Virtual function called when plugin is disabled.
func _disable_plugin():
	remove_autoload_singleton("escoria")

	InputMap.erase_action(get_node("escoria").inputs_manager.SWITCH_ACTION_VERB)
	InputMap.erase_action(get_node("escoria").inputs_manager.ESC_SHOW_DEBUG_PROMPT)


# Setup Escoria
func _enter_tree():
	_enable_plugin()


func _ready():
	# Prepare settings
	set_escoria_main_settings()
	set_escoria_debug_settings()
	set_escoria_ui_settings()
	set_escoria_sound_settings()
	set_escoria_platform_settings()
	ProjectSettings.save()


# Prepare the settings in the Escoria UI category
func set_escoria_ui_settings():
	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.DEFAULT_DIALOG_TYPE,
		"",
		{
			"type": TYPE_STRING
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.GAME_SCENE,
		"",
		{
			"name": get_node("escoria").project_settings_manager.GAME_SCENE,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn, *.scn"
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.ITEMS_AUTOREGISTER_PATH,
		"res://game/items/escitems/",
		{
			"name": get_node("escoria").project_settings_manager.ITEMS_AUTOREGISTER_PATH,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.DEFAULT_TRANSITION,
		"curtain",
		{
			"name": get_node("escoria").project_settings_manager.DEFAULT_TRANSITION,
			"type": TYPE_STRING
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.TRANSITION_PATHS,
		[
			"res://addons/escoria-core/game/scenes/transitions/shaders/"
		],
		{
			"name": get_node("escoria").project_settings_manager.TRANSITION_PATHS,
			"type": TYPE_STRING_ARRAY,
			"hint": PROPERTY_HINT_DIR
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.INVENTORY_ITEM_SIZE,
		Vector2(72, 72),
		{
			"name": get_node("escoria").project_settings_manager.INVENTORY_ITEM_SIZE,
			"type": TYPE_VECTOR2
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.DIALOG_MANAGERS,
		[],
		{
			"type": TYPE_STRING_ARRAY
		}
	)


# Prepare the settings in the Escoria main category
func set_escoria_main_settings():
	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.GAME_VERSION,
		"",
		{
			"type": TYPE_STRING
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.GAME_START_SCRIPT,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.esc"
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.FORCE_QUIT,
		true,
		{
			"type": TYPE_BOOL
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.COMMAND_DIRECTORIES,
		[
			"res://addons/escoria-core/game/core-scripts/esc/commands"
		],
		{
			"type": TYPE_ARRAY,
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.TEXT_LANG,
		TranslationServer.get_locale(),
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.VOICE_LANG,
		TranslationServer.get_locale(),
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SAVEGAMES_PATH,
		"user://saves/",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SETTINGS_PATH,
		"user://",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.GAME_MIGRATION_PATH,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)


# Prepare the settings in the Escoria debug category
func set_escoria_debug_settings():
	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.TERMINATE_ON_WARNINGS,
		false,
		{
			"type": TYPE_BOOL
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.TERMINATE_ON_ERRORS,
		true,
		{
			"type": TYPE_BOOL
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.DEVELOPMENT_LANG,
		"en",
		{
			"type": TYPE_STRING
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.LOG_LEVEL,
		"ERROR",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "ERROR,WARNING,INFO,DEBUG"
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.LOG_FILE_PATH,
		"user://",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.LOG_FILE_PATH,
		"We're sorry, but the game crashed. Please send us the " +
		"following files:\n\n%s",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.ENABLE_ROOM_SELECTOR,
		false,
		{
			"type": TYPE_BOOL
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.ROOM_SELECTOR_ROOM_DIR,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)


# Prepare the settings in the Escoria sound settings
func set_escoria_sound_settings():
	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.MASTER_VOLUME,
		1,
		{
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.MUSIC_VOLUME,
		1,
		{
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SFX_VOLUME,
		1,
		{
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SPEECH_VOLUME,
		1,
		{
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SPEECH_ENABLED,
		1,
		{
			"type": TYPE_BOOL
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SPEECH_FOLDER,
		"res://speech",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SPEECH_EXTENSION,
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
	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SKIP_CACHE,
		false,
		{
			"type": TYPE_BOOL
		}
	)

	get_node("escoria").project_settings_manager.register_setting(
		get_node("escoria").project_settings_manager.SKIP_CACHE_MOBILE,
		true,
		{
			"type": TYPE_BOOL
		}
	)


# Uninstall plugin
func _exit_tree():
	_disable_plugin()

