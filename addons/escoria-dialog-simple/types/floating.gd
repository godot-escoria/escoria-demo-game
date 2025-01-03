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
@onready var tween: Tween3 = Tween3.new(self)

# The node showing the text
@onready var text_node: RichTextLabel = self

# Whether the dialog manager is paused
@onready var is_paused: bool = true

var dialog_location_node = null

# Enable bbcode and catch the signal when a tween completed
func _ready():
	_text_time_per_character = ProjectSettings.get_setting(
		SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS
	)

	if _text_time_per_character < 0:
		escoria.logger.warn(
			self,
			"%s setting must be a non-negative number. Will use default value of %s." %
				[
					SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS,
					SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE
				]
		)

		_text_time_per_character = SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE

	_fast_text_time_per_character = ProjectSettings.get_setting(
		SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_FAST
	)

	if _fast_text_time_per_character < 0:
		escoria.logger.warn(
			self,
			"%s setting must be a non-negative number. Will use default value of %s." %
				[
					SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_FAST,
					SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE
				]
		)

		_fast_text_time_per_character = SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE

	_reading_speed_in_wpm = ProjectSettings.get_setting(
		SimpleDialogSettings.READING_SPEED_IN_WPM
	)

	if _reading_speed_in_wpm <= 0:
		escoria.logger.warn(
			self,
			"%s setting must be a positive number. Will use default value of %s." %
				[
					SimpleDialogSettings.READING_SPEED_IN_WPM,
					SimpleDialogSettings.READING_SPEED_IN_WPM_DEFAULT_VALUE
				]
		)

		_reading_speed_in_wpm = SimpleDialogSettings.READING_SPEED_IN_WPM_DEFAULT_VALUE

	_word_regex.compile("\\S+")

	bbcode_enabled = true
	
	tween.finished.connect(_on_dialog_line_typed.bind("", ""))

	tree_exiting.connect(_on_tree_exiting)

	escoria.paused.connect(_on_paused)
	escoria.resumed.connect(_on_resumed)

	_current_line = ""


func _process(delta):
	if _current_character.is_inside_tree() and \
			is_instance_valid(dialog_location_node):
		# Position the RichTextLabel on the character's dialog position, if any.
		position = dialog_location_node.get_global_transform_with_canvas().origin
		position.x -= size.x / 2

		_account_for_margin_x()

		_account_for_margin_y()


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

	var dialog_location_count:int = 0

	for c in escoria.object_manager.get_object(character).node.get_children():
		if c is Marker2D:
			# Identify any Postion2D nodes
			if c is ESCDialogLocation:
				dialog_location_count += 1
				dialog_location_node = c

	if dialog_location_count > 1:
		escoria.logger.warn(
			self,
			"Multiple ESCDialogLocation nodes found " +
			"object %s. Last one will be used." % _current_character)

	# Set text color to color set in the actor
	var text_color = _current_character.dialog_color
	var text_color_html = text_color.to_html(false)

	text_node.text = "[center][color=#" + text_color_html + "]" \
		.format([text_color_html]) + tr(line) + "[/color][center]"

	if _current_character.is_inside_tree() and \
			is_instance_valid(dialog_location_node):
		position = dialog_location_node.get_global_transform_with_canvas().origin

		position.x -= size.x / 2
	else:
		position.x = 0
		size.x = ProjectSettings.get_setting("display/window/size/viewport_width")

	_account_for_margin_x()

	_account_for_margin_y()

	_current_character.start_talking()

	text_node.visible_ratio = 0.0
	var time_show_full_text = _text_time_per_character / 1000 * len(_current_line)

	tween.reset()

	tween.interpolate_property(text_node, "visible_ratio",
		0.0, 1.0, time_show_full_text,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.play()
	set_process(true)


# Called by the dialog player when user wants to finish dialogue fast.
func speedup():
	if not _is_speeding_up:
		_is_speeding_up = true
		var time_show_full_text = _fast_text_time_per_character / 1000 * len(_current_line)

		tween.reset()

		tween.interpolate_property(text_node, "visible_ratio",
			text_node.visible_ratio, 1.0, time_show_full_text,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.play()


# Called by the dialog player when user wants to finish dialogue immediately.
func finish():
	tween.reset()

	tween.interpolate_property(text_node, "visible_ratio",
		text_node.visible_ratio, 1.0, 0.0)
	tween.play()


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
	$Timer.connect("timeout", Callable(self, "_on_dialog_finished"))

	say_visible.emit()


func _calculate_time_to_disappear() -> float:
	return (_get_number_of_words() / _reading_speed_in_wpm as float) * 60


func _get_number_of_words() -> int:
	return _word_regex.search_all(text_node.get_text()).size()


# Ending the dialog
func _on_dialog_finished():
	# Only trigger to clear the text if we aren't limiting the clearing trigger to a click.
	if not ESCProjectSettingsManager.get_setting(SimpleDialogSettings.CLEAR_TEXT_BY_CLICK_ONLY):
		say_finished.emit()


# Handler managing pause notification from Escoria
func _on_paused():
	if tween.is_active():
		is_paused = true
		tween.stop()


# Handler managing resume notification from Escoria
func _on_resumed():
	if not tween.is_running():
		is_paused = false
		tween.resume()


 # Handler to deal with this node being removed
func _on_tree_exiting() -> void:
	_stop_character_talking()


func _stop_character_talking():
	# Make the speaking item animation stop talking, if it is still alive
	if is_instance_valid(_current_character) and _current_character != null:
		_current_character.stop_talking()


func _account_for_margin_x() -> void:
	if position.x < 0:
		position.x = 0

	var screen_margin_x = position.x + size.x - \
			ProjectSettings.get("display/window/size/viewport_width")

	if screen_margin_x > 0:
		position.x -= screen_margin_x


func _account_for_margin_y() -> void:
	if position.y < 0:
		position.y = 0

	var screen_margin_y = position.y + size.y - \
			ProjectSettings.get("display/window/size/viewport_height")

	if screen_margin_y > 0:
		position.y -= screen_margin_y
