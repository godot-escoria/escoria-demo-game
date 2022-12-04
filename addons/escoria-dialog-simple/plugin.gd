# A simple dialog manager for Escoria
tool
extends EditorPlugin
class_name SimpleDialogPlugin


const MANAGER_CLASS="res://addons/escoria-dialog-simple/esc_dialog_simple.gd"
const SETTINGS_ROOT="escoria/dialog_simple"

const AVATARS_PATH = "%s/avatars_path" % SETTINGS_ROOT
const TEXT_TIME_PER_LETTER_MS = "%s/text_time_per_letter_ms" % SETTINGS_ROOT
const TEXT_TIME_PER_LETTER_MS_FAST = "%s/text_time_per_fast_letter_ms" % SETTINGS_ROOT
const READING_SPEED_IN_WPM = "%s/reading_speed_in_wpm" % SETTINGS_ROOT
const CLEAR_TEXT_BY_CLICK_ONLY = "%s/clear_text_by_click_only" % SETTINGS_ROOT
const LEFT_CLICK_ACTION = "%s/left_click_action" % SETTINGS_ROOT
const STOP_TALKING_ANIMATION_ON = "%s/stop_talking_animation_on" % SETTINGS_ROOT

const LEFT_CLICK_ACTION_SPEED_UP = "Speed up"
const LEFT_CLICK_ACTION_INSTANT_FINISH = "Instant finish"
const LEFT_CLICK_ACTION_NOTHING = "None"

const STOP_TALKING_ANIMATION_ON_END_OF_TEXT = "End of text"
const STOP_TALKING_ANIMATION_ON_END_OF_AUDIO = "End of audio"

const READING_SPEED_IN_WPM_DEFAULT_VALUE = 200
const TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE = 100
const TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE = 25


var leftClickActions: Array = [
	LEFT_CLICK_ACTION_SPEED_UP,
	LEFT_CLICK_ACTION_INSTANT_FINISH,
	LEFT_CLICK_ACTION_NOTHING
]

var stopTalkingAnimationOnOptions: Array = [
	STOP_TALKING_ANIMATION_ON_END_OF_TEXT,
	STOP_TALKING_ANIMATION_ON_END_OF_AUDIO
]


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
		TEXT_TIME_PER_LETTER_MS
	)

	ESCProjectSettingsManager.remove_setting(
		TEXT_TIME_PER_LETTER_MS_FAST
	)

	ESCProjectSettingsManager.remove_setting(
		CLEAR_TEXT_BY_CLICK_ONLY
	)

	ESCProjectSettingsManager.remove_setting(
		READING_SPEED_IN_WPM
	)

	ESCProjectSettingsManager.remove_setting(
		LEFT_CLICK_ACTION
	)

	ESCProjectSettingsManager.remove_setting(
		STOP_TALKING_ANIMATION_ON
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
			TEXT_TIME_PER_LETTER_MS,
			TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE,
			{
				"type": TYPE_REAL
			}
		)

		ESCProjectSettingsManager.register_setting(
			TEXT_TIME_PER_LETTER_MS_FAST,
			TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE,
			{
				"type": TYPE_REAL
			}
		)

		ESCProjectSettingsManager.register_setting(
			CLEAR_TEXT_BY_CLICK_ONLY,
			false,
			{
				"type": TYPE_BOOL
			}
		)

		ESCProjectSettingsManager.register_setting(
			READING_SPEED_IN_WPM,
			READING_SPEED_IN_WPM_DEFAULT_VALUE,
			{
				"type": TYPE_INT
			}
		)

		var leftClickActionsString: String = ",".join(leftClickActions)

		ESCProjectSettingsManager.register_setting(
			LEFT_CLICK_ACTION,
			LEFT_CLICK_ACTION_SPEED_UP,
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": leftClickActionsString
			}
		)

		var stopTalkingAnimationOnOptionsString: String = ",".join(stopTalkingAnimationOnOptions)

		ESCProjectSettingsManager.register_setting(
			STOP_TALKING_ANIMATION_ON,
			STOP_TALKING_ANIMATION_ON_END_OF_AUDIO,
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": stopTalkingAnimationOnOptionsString
			}
		)

	else:
		get_editor_interface().set_plugin_enabled(
			get_plugin_name(),
			false
		)
