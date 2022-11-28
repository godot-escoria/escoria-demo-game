# A simple dialog manager for Escoria
tool
extends EditorPlugin

const MANAGER_CLASS="res://addons/escoria-dialog-simple/esc_dialog_simple.gd"
const SETTINGS_ROOT="escoria/dialog_simple"

const AVATARS_PATH = "%s/avatars_path" % SETTINGS_ROOT
const TEXT_SPEED_PER_CHARACTER = "%s/text_speed_per_character" % SETTINGS_ROOT
const FAST_TEXT_SPEED_PER_CHARACTER = "%s/fast_text_speed_per_character" % SETTINGS_ROOT
const MAX_TIME_TO_DISAPPEAR = "%s/max_time_to_disappear" % SETTINGS_ROOT
const SKIP_DIALOGS = "%s/skip_dialogs" % SETTINGS_ROOT
const READING_SPEED_IN_WPM = "%s/reading_speed_in_wpm" % SETTINGS_ROOT

# Override function to return the plugin name.
func get_plugin_name():
	return "escoria-dialog-simple"


# Unregister ourselves
func disable_plugin():
	print("Disabling plugin Escoria Dialog Simple")
	ESCProjectSettingsManager.remove_setting(
		ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE
	)

	ESCProjectSettingsManager.remove_setting(
		AVATARS_PATH
	)

	ESCProjectSettingsManager.remove_setting(
		TEXT_SPEED_PER_CHARACTER
	)

	ESCProjectSettingsManager.remove_setting(
		FAST_TEXT_SPEED_PER_CHARACTER
	)

	ESCProjectSettingsManager.remove_setting(
		READING_SPEED_IN_WPM
	)

	ESCProjectSettingsManager.remove_setting(
		MAX_TIME_TO_DISAPPEAR
	)

	EscoriaPlugin.deregister_dialog_manager(MANAGER_CLASS)


# Add ourselves to the list of dialog managers
func enable_plugin():
	print("Enabling plugin Escoria Dialog Simple")

	if EscoriaPlugin.register_dialog_manager(self, MANAGER_CLASS):
		ESCProjectSettingsManager.register_setting(
			ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE,
			"floating",
			{
				"type": TYPE_STRING
			}
		)

		ESCProjectSettingsManager.register_setting(
			AVATARS_PATH,
			"res://game/dialog_avatars",
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_DIR
			}
		)

		ESCProjectSettingsManager.register_setting(
			TEXT_SPEED_PER_CHARACTER,
			0.1,
			{
				"type": TYPE_REAL
			}
		)

		ESCProjectSettingsManager.register_setting(
			FAST_TEXT_SPEED_PER_CHARACTER,
			0.25,
			{
				"type": TYPE_REAL
			}
		)

		ESCProjectSettingsManager.register_setting(
			READING_SPEED_IN_WPM,
			200,
			{
				"type": TYPE_INT
			}
		)

		ESCProjectSettingsManager.register_setting(
			MAX_TIME_TO_DISAPPEAR,
			1.0,
			{
				"type": TYPE_INT
			}
		)

		ESCProjectSettingsManager.register_setting(
			SKIP_DIALOGS,
			true,
			{
				"type": TYPE_BOOL
			}
		)
		#escoria.settings_manager.custom_settings[SKIP_DIALOGS] = true
	else:
		get_editor_interface().set_plugin_enabled(
			get_plugin_name(),
			false
		)
