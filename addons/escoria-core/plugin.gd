@tool
## Plugin script to initialize Escoria
extends EditorPlugin

## Comma separator const used to build enabled extensions.
const COMMA_SEPARATOR = ","

## ESC files extension.
const ESC_SCRIPT_EXTENSION = "esc"
const ASH_SCRIPT_EXTENSION = "ash"
const ASHES_ANALYZER_MENU_ITEM = "Analyze ASHES Scripts"


## The warning popup displayed on escoria-core enabling.
var popup_info: AcceptDialog

## ASHES scripts analyzer. Needed to allow calling the analyzer from 
## Project>Tools menu.
var _compiler_analyzer: ESCAshesAnalyzer = ESCAshesAnalyzer.new()


## Virtual function called when plugin is enabled.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _enable_plugin():
	add_autoload_singleton(
		"escoria",
		"res://addons/escoria-core/game/esc_autoload.gd"
	)
	# Prepare settings
	_set_escoria_main_settings()
	_set_escoria_debug_settings()
	_set_escoria_ui_settings()
	_set_escoria_sound_settings()
	_set_escoria_platform_settings()
	_set_filesystem_show_esc_files()

	# Define standard settings
	ProjectSettings.set_setting(
		"application/run/main_scene",
		"res://addons/escoria-core/game/main_scene.tscn"
	)

	ProjectSettings.set_setting(
		"audio/buses/default_bus_layout",
		"res://addons/escoria-core/buses/default_bus_layout.tres"
	)

	popup_info = AcceptDialog.new()
	popup_info.dialog_text = """You enabled escoria-core plugin.

	Please ignore error messages in Output console and reload your project using
	Godot editor's \"Project / Reload Current Project\" menu.
	"""
	popup_info.confirmed.connect(self._on_warning_popup_confirmed, CONNECT_ONE_SHOT)
	get_editor_interface().get_editor_main_screen().add_child(popup_info)
	popup_info.popup_centered()


## Callback for warning popup displayed on escoria-core plugin enabling.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _on_warning_popup_confirmed():
	popup_info.queue_free()


## Virtual function called when plugin is disabled.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _disable_plugin():
	remove_autoload_singleton("escoria")
	_set_filesystem_hide_esc_files()


## Called when Escoria plugin gets added to Godot Editor's tree.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _enter_tree():
	# have to add this here since reloading the project doesn't re-add the Tools menu item
	add_tool_menu_item(ASHES_ANALYZER_MENU_ITEM, _compiler_analyzer.analyze)


## Called when Escoria plugin gets removed from Godot Editor's tree.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _exit_tree():
	remove_tool_menu_item(ASHES_ANALYZER_MENU_ITEM)


## Prepare the settings in the Escoria UI category[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _set_escoria_ui_settings():
	register_setting(
		ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE,
		"",
		{
			"type": TYPE_STRING
		}
	)
	print("Default dialog type has been reset!")

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
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM_SUGGESTION,
			"hint_string": "instant,fade_black,fade_white,curtain"
		}
	)

	register_setting(
		ESCProjectSettingsManager.TRANSITION_PATHS,
		[
			"res://addons/escoria-core/game/scenes/transitions/shaders/"
		],
		{
			"name": ESCProjectSettingsManager.TRANSITION_PATHS,
			"type": TYPE_PACKED_STRING_ARRAY,
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
			"type": TYPE_PACKED_STRING_ARRAY
		}
	)


## Prepare the settings in the Escoria main category[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _set_escoria_main_settings():
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
			"hint_string": "*.esc,*.ash"
		}
	)

	register_setting(
		ESCProjectSettingsManager.ACTION_DEFAULT_SCRIPT,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.esc,*.ash"
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

	register_setting(
		ESCProjectSettingsManager.WINDOW_MODE,
		false,
		{
			"type": TYPE_BOOL,
		}
	)


## Prepare the settings in the Escoria debug category[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _set_escoria_debug_settings():
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

	register_setting(
		ESCProjectSettingsManager.ENABLE_HOVER_STACK_VIEWER,
		false,
		{
			"type": TYPE_BOOL
		}
	)

	register_setting(
		ESCProjectSettingsManager.PERFORM_SCRIPT_ANALYSIS_AT_RUNTIME,
		true,
		{
			"type": TYPE_BOOL
		}
	)


## Prepare the settings in the Escoria sound settings[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _set_escoria_sound_settings():
	register_setting(
		ESCProjectSettingsManager.MASTER_VOLUME,
		1,
		{
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	register_setting(
		ESCProjectSettingsManager.MUSIC_VOLUME,
		1,
		{
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	register_setting(
		ESCProjectSettingsManager.SFX_VOLUME,
		1,
		{
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)

	register_setting(
		ESCProjectSettingsManager.SPEECH_VOLUME,
		1,
		{
			"type": TYPE_FLOAT,
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


## Prepare the settings in the Escoria platform category and may need special setting per build.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _set_escoria_platform_settings():
	# Skip cache - certain platforms (esp. mobile) lack memory for caching
	# scenes. If set to true, all generic scenes (UI, inventory, etc) will be
	# loaded as any other scene.
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


## Register a new project setting if it hasn't been defined already[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |name|`String`|Fully qualified Project Settings key to register.|yes|[br]
## |default|`Variant`|Default value|yes|[br]
## |info|`Dictionary`|Property info for the setting|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
static func register_setting(name: String, default: Variant, info: Dictionary) -> void:
	if not ProjectSettings.has_setting(name):
		# Only core settings should set this to true. Settings configured in
		# plugins should not set this to true.
		info["core_setting"] = "true"
		ProjectSettings.set_setting(
			name,
			default
		)
		info.name = name
		ProjectSettings.add_property_info(info)


## Sets the Godot Editor settings to display ESC files in the filesystem.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _set_filesystem_show_esc_files():
	print("setting esc and ash files display")
	var settings = EditorInterface.get_editor_settings()
	var displayed_extensions: PackedStringArray = settings.get_setting(
			"docks/filesystem/textfile_extensions").split(COMMA_SEPARATOR)
	var needs_modification: bool = false
	if not ESC_SCRIPT_EXTENSION in displayed_extensions:
		displayed_extensions.append(ESC_SCRIPT_EXTENSION)
		needs_modification = true
	if not ASH_SCRIPT_EXTENSION in displayed_extensions:
		displayed_extensions.append(ASH_SCRIPT_EXTENSION)
		needs_modification = true
	if needs_modification:
		settings.set_setting(
			"docks/filesystem/textfile_extensions",
			COMMA_SEPARATOR.join(displayed_extensions)
			)
	if not displayed_extensions.has(ASH_SCRIPT_EXTENSION):
		displayed_extensions.append(ASH_SCRIPT_EXTENSION)
		settings.set_setting(
			"docks/filesystem/textfile_extensions",
			COMMA_SEPARATOR.join(displayed_extensions)
			)


## Sets the Godot Editor settings to hide ESC and ASH files in the filesystem.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _set_filesystem_hide_esc_files():
	print("setting esc files hide")
	var settings = EditorInterface.get_editor_settings()
	var displayed_extensions: PackedStringArray = settings.get_setting(
			"docks/filesystem/textfile_extensions").split(COMMA_SEPARATOR)
	var index_esc: int = displayed_extensions.find(ESC_SCRIPT_EXTENSION)
	var index_ash: int = displayed_extensions.find(ASH_SCRIPT_EXTENSION)
	var needs_modification: bool = false
	while index_esc != -1:
		displayed_extensions.remove_at(index_esc)
		index_esc = displayed_extensions.find(ESC_SCRIPT_EXTENSION)
		needs_modification = true
	while index_ash != -1:
		displayed_extensions.remove_at(index_ash)
		index_ash = displayed_extensions.find(ASH_SCRIPT_EXTENSION)
		needs_modification = true
	if needs_modification:
		settings.set_setting(
			"docks/filesystem/textfile_extensions",
			COMMA_SEPARATOR.join(displayed_extensions)
			)
