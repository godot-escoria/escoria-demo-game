class_name DialogPluginConstants


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


var left_click_actions: PoolStringArray = [
	LEFT_CLICK_ACTION_SPEED_UP,
	LEFT_CLICK_ACTION_INSTANT_FINISH,
	LEFT_CLICK_ACTION_NOTHING
]

var stop_talking_animation_on_options: PoolStringArray = [
	STOP_TALKING_ANIMATION_ON_END_OF_TEXT,
	STOP_TALKING_ANIMATION_ON_END_OF_AUDIO
]
