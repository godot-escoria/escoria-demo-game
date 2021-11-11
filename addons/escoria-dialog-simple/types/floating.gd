# A dialog UI using a label above the head of the character
extends RichTextLabel


# Signal emitted when text has been said
signal say_finished


# The text speed per character for normal display
var _text_speed_per_character

# The text speed per character if the dialog line is skipped
var _fast_text_speed_per_character

# The time to wait before the dialog is finished
var _max_time_to_text_disappear


# Current character speaking, to keep track of reference for animation purposes
var _current_character

# Wether the current dialog is speeding up
var _is_speeding_up: bool = false


# Tween node for text animation
onready var tween: Tween = $Tween

# The node showing the text
onready var text_node: RichTextLabel = self


# Enable bbcode and catch the signal when a tween completed
func _ready():
	_text_speed_per_character = ProjectSettings.get_setting(
		"escoria/dialog_simple/text_speed_per_character"
	)
	_fast_text_speed_per_character = ProjectSettings.get_setting(
		"escoria/dialog_simple/fast_text_speed_per_character"
	)
	_max_time_to_text_disappear = ProjectSettings.get_setting(
		"escoria/dialog_simple/max_time_to_disappear"
	)
	bbcode_enabled = true
	$Tween.connect("tween_completed", self, "_on_dialog_line_typed")


func _process(delta):
	# Position the RichTextLabel on the character's dialog position, if any.
	rect_position = _current_character.get_node("dialog_position") \
		.get_global_transform_with_canvas().origin
	rect_position.x -= rect_size.x / 2
	

# Make a character say something
#
# #### Parameters
# - character: The global id of the character speaking
# - line: Line to say
func say(character: String, line: String) :
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
		
	_current_character.start_talking()
	
	text_node.percent_visible = 0.0
	var time_show_full_text = _text_speed_per_character * len(line)
	
	tween.interpolate_property(text_node, "percent_visible",
		0.0, 1.0, time_show_full_text,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	set_process(true)


# Called by the dialog player when user wants to finish dialog fast.
func speedup():
	if not _is_speeding_up:
		_is_speeding_up = true
		tween.remove_all()
		tween.interpolate_property(text_node, "percent_visible",
			text_node.percent_visible, 1.0, _fast_text_speed_per_character,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()


# The dialog line was printed, start the waiting time and then finish
# the dialog
func _on_dialog_line_typed(object, key):
	text_node.visible_characters = -1
	$Timer.start(_max_time_to_text_disappear)
	$Timer.connect("timeout", self, "_on_dialog_finished")


# Ending the dialog
func _on_dialog_finished():
	# Make the speaking item animation stop talking, if it is still alive
	if is_instance_valid(_current_character) and _current_character != null:
		_current_character.stop_talking()
	emit_signal("say_finished")
