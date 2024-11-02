@tool
# A simple dialog manager for Escoria
extends EditorPlugin

const MANAGER_CLASS = "res://addons/escoria-dialog-simple/esc_dialog_simple.gd"

const READING_SPEED_IN_WPM_DEFAULT_VALUE = 200
const TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE = 100
const TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE = 25


var left_click_actions: PackedStringArray = [
	SimpleDialogSettings.LEFT_CLICK_ACTION_SPEED_UP,
	SimpleDialogSettings.LEFT_CLICK_ACTION_INSTANT_FINISH,
	SimpleDialogSettings.LEFT_CLICK_ACTION_NOTHING
]

var stop_talking_animation_on_options: PackedStringArray = [
	SimpleDialogSettings.STOP_TALKING_ANIMATION_ON_END_OF_TEXT,
	SimpleDialogSettings.STOP_TALKING_ANIMATION_ON_END_OF_AUDIO
]


# Override function to return the plugin name.
func _get_plugin_name():
	return "escoria-dialog-simple"


# Unregister ourselves
func _disable_plugin():
	print("Disabling plugin Escoria Dialog Simple")
	ESCProjectSettingsManager.remove_setting(
		ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogSettings.AVATARS_PATH
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_FAST
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogSettings.CLEAR_TEXT_BY_CLICK_ONLY
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogSettings.READING_SPEED_IN_WPM
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogSettings.LEFT_CLICK_ACTION
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogSettings.STOP_TALKING_ANIMATION_ON
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
			SimpleDialogSettings.AVATARS_PATH,
			"res://game/dialog_avatars",
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_DIR
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS,
			TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE,
			{
				"type": TYPE_FLOAT
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_FAST,
			TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE,
			{
				"type": TYPE_FLOAT
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogSettings.CLEAR_TEXT_BY_CLICK_ONLY,
			false,
			{
				"type": TYPE_BOOL
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogSettings.READING_SPEED_IN_WPM,
			READING_SPEED_IN_WPM_DEFAULT_VALUE,
			{
				"type": TYPE_INT
			}
		)

		var left_click_actions_string: String = ",".join(left_click_actions)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogSettings.LEFT_CLICK_ACTION,
			SimpleDialogSettings.LEFT_CLICK_ACTION_SPEED_UP,
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": left_click_actions_string
			}
		)

		var stop_talking_animation_on_options_string: String = ",".join(stop_talking_animation_on_options)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogSettings.STOP_TALKING_ANIMATION_ON,
			SimpleDialogSettings.STOP_TALKING_ANIMATION_ON_END_OF_AUDIO,
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": stop_talking_animation_on_options_string
			}
		)

	else:
		get_editor_interface().set_plugin_enabled(
			_get_plugin_name(),
			false
		)
