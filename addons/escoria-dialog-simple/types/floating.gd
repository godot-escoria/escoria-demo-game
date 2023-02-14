# A dialog UI using a label above the head of the character
extends RichTextLabel


# Signal emitted when text has been said
signal say_finished

# Signal emitted when text has just become fully visible
signal say_visible


# The text speed per character for normal display
var _text_time_per_character: float

# The text speed per character if the dialog line is skipped
var _fast_text_time_per_character: float

# The reading speed to be used in determining the length of time text remains
# on the screen.
var _reading_speed_in_wpm: int

# Used to extract words from lines of text.
var _word_regex: RegEx = RegEx.new()


# Current character speaking, to keep track of reference for animation purposes
var _current_character

# Whether the current dialog is speeding up
var _is_speeding_up: bool = false

# The current line of text being displayed.
var _current_line: String


# Tween node for text animation
onready var tween: Tween = $Tween

# The node showing the text
onready var text_node: RichTextLabel = self

# Whether the dialog manager is paused
onready var is_paused: bool = true


# Enable bbcode and catch the signal when a tween completed
func _ready():
	_text_time_per_character = ProjectSettings.get_setting(
		ESCSimpleDialogSettingsManager.TEXT_TIME_PER_LETTER_MS
	)

	if _text_time_per_character < 0:
		escoria.logger.warn(
			self,
			"%s setting must be a non-negative number. Will use default value of %s." %
				[
					ESCSimpleDialogSettingsManager.TEXT_TIME_PER_LETTER_MS,
					ESCSimpleDialogSettingsManager.TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE
				]
		)

		_text_time_per_character = ESCSimpleDialogSettingsManager.TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE

	_fast_text_time_per_character = ProjectSettings.get_setting(
		ESCSimpleDialogSettingsManager.TEXT_TIME_PER_LETTER_MS_FAST
	)

	if _fast_text_time_per_character < 0:
		escoria.logger.warn(
			self,
			"%s setting must be a non-negative number. Will use default value of %s." %
				[
					ESCSimpleDialogSettingsManager.TEXT_TIME_PER_LETTER_MS_FAST,
					ESCSimpleDialogSettingsManager.TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE
				]
		)

		_fast_text_time_per_character = ESCSimpleDialogSettingsManager.TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE

	_reading_speed_in_wpm = ProjectSettings.get_setting(
		ESCSimpleDialogSettingsManager.READING_SPEED_IN_WPM
	)

	if _reading_speed_in_wpm <= 0:
		escoria.logger.warn(
			self,
			"%s setting must be a positive number. Will use default value of %s." %
				[
					ESCSimpleDialogSettingsManager.READING_SPEED_IN_WPM,
					ESCSimpleDialogSettingsManager.READING_SPEED_IN_WPM_DEFAULT_VALUE
				]
		)

		_reading_speed_in_wpm = ESCSimpleDialogSettingsManager.READING_SPEED_IN_WPM_DEFAULT_VALUE

	_word_regex.compile("\\S+")

	bbcode_enabled = true
	$Tween.connect("tween_completed", self, "_on_dialog_line_typed")

	connect("tree_exiting", self, "_on_tree_exiting")

	escoria.connect("paused", self, "_on_paused")
	escoria.connect("resumed", self, "_on_resumed")

	_current_line = ""


func _process(delta):
	if _current_character.is_inside_tree() and \
			_current_character.has_node("dialog_position"):
		# Position the RichTextLabel on the character's dialog position, if any.
		rect_position = _current_character.get_node("dialog_position") \
			.get_global_transform_with_canvas().origin
		rect_position.x -= rect_size.x / 2

		if rect_position.x < 0:
			rect_position.x = 0

		var screen_margin = rect_position.x + rect_size.x - \
				ProjectSettings.get("display/window/size/width")

		if screen_margin > 0:
			rect_position.x -= screen_margin


# Make a character say something
#
# #### Parameters
# - character: The global id of the character speaking
# - line: Line to say
func say(character: String, line: String) :
	_current_line = line

	show()

	_is_speeding_up = false

	# Position the RichTextLabel on the character's dialog position, if any.
	_current_character = escoria.object_manager.get_object(character).node

	# Set text color to color set in the actor
	var text_color = _current_character.dialog_color
	var text_color_html = text_color.to_html(false)

	text_node.bbcode_text = "[center][color=#" + text_color_html + "]" \
		.format([text_color_html]) + tr(line) + "[/color][center]"

	if _current_character.is_inside_tree() and \
			_current_character.has_node("dialog_position"):
		rect_position = _current_character.get_node(
			"dialog_position"
		).get_global_transform_with_canvas().origin
		rect_position.x -= rect_size.x / 2
	else:
		rect_position.x = 0
		rect_size.x = ProjectSettings.get_setting("display/window/size/width")

	if rect_position.x < 0:
		rect_position.x = 0

	var screen_margin = rect_position.x + rect_size.x - \
			ProjectSettings.get("display/window/size/width")

	if screen_margin > 0:
		rect_position.x -= screen_margin

	_current_character.start_talking()

	text_node.percent_visible = 0.0
	var time_show_full_text = _text_time_per_character / 1000 * len(_current_line)

	tween.interpolate_property(text_node, "percent_visible",
		0.0, 1.0, time_show_full_text,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	set_process(true)


# Called by the dialog player when user wants to finish dialogue fast.
func speedup():
	if not _is_speeding_up:
		_is_speeding_up = true
		var time_show_full_text = _fast_text_time_per_character / 1000 * len(_current_line)

		tween.remove_all()
		tween.interpolate_property(text_node, "percent_visible",
			text_node.percent_visible, 1.0, time_show_full_text,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()


# Called by the dialog player when user wants to finish dialogue immediately.
func finish():
	tween.remove_all()
	tween.interpolate_property(text_node, "percent_visible",
		text_node.percent_visible, 1.0, 0.0)
	tween.start()


# To be called if voice audio has finished.
func voice_audio_finished():
		_stop_character_talking()


# The dialog line was printed, start the waiting time and then finish
# the dialog
func _on_dialog_line_typed(object, key):
	_stop_character_talking()
	text_node.visible_characters = -1

	var time_to_disappear: float = _calculate_time_to_disappear()
	$Timer.start(time_to_disappear)
	$Timer.connect("timeout", self, "_on_dialog_finished")

	emit_signal("say_visible")


func _calculate_time_to_disappear() -> float:
	return (_get_number_of_words() / _reading_speed_in_wpm as float) * 60


func _get_number_of_words() -> int:
	return _word_regex.search_all(text_node.get_text()).size()


# Ending the dialog
func _on_dialog_finished():
	# Only trigger to clear the text if we aren't limiting the clearing trigger to a click.
	if not ESCProjectSettingsManager.get_setting(ESCSimpleDialogSettingsManager.CLEAR_TEXT_BY_CLICK_ONLY):
		emit_signal("say_finished")


# Handler managing pause notification from Escoria
func _on_paused():
	if tween.is_active():
		is_paused = true
		tween.stop_all()


# Handler managing resume notification from Escoria
func _on_resumed():
	if not tween.is_active():
		is_paused = false
		tween.resume_all()


 # Handler to deal with this node being removed
func _on_tree_exiting() -> void:
	_stop_character_talking()


func _stop_character_talking():
	# Make the speaking item animation stop talking, if it is still alive
	if is_instance_valid(_current_character) and _current_character != null:
		_current_character.stop_talking()
