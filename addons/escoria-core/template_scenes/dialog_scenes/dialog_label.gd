# A dialog UI using a label above the head of the character
extends RichTextLabel


# Signal emitted when a dialog line has started
signal dialog_line_started

# Signal emitted when a dialog line has finished
signal dialog_line_finished


# The text speed per character for normal display
export(float, 0.0, 0.3) var text_speed_per_character = 0.1

# The text speed per character if the dialog line is skipped
export(float) var fast_text_speed_per_character = 0.25

# The time to wait before the dialog is finished
export(float) var max_time_to_text_disappear = 2.0


# Current character speaking, to keep track of reference for animation purposes
var current_character


# Tween node for text animation
onready var tween = $Tween

# The node showing the text
onready var text_node = self


# Enable bbcode and catch the signal when a tween completed
func _ready():
	bbcode_enabled = true
	$Tween.connect("tween_completed", self, "_on_dialog_line_typed")


# Make a character say something
#
# #### Parameters
# - character: The global id of the character speaking
# - line: Line to say
func say(character: String, line: String) :
	show()
	
	emit_signal("dialog_line_started")
	
	# Position the RichTextLabel on the character's dialog position, if any.
	current_character = escoria.object_manager.get_object(character).node
	rect_position = current_character.get_node("dialog_position").get_global_transform_with_canvas().origin
	rect_position.x -= rect_size.x / 2
	
	current_character.start_talking()
	
	# Set text color to color set in the actor
	var text_color = current_character.dialog_color
	var text_color_html = text_color.to_html(false)
	
	text_node.bbcode_text = "[center][color=#" + text_color_html + "]" \
		.format([text_color_html]) + tr(line) + "[/color][center]"
	
	text_node.percent_visible = 0.0
	var time_show_full_text = text_speed_per_character * len(line)
	
	tween.interpolate_property(text_node, "percent_visible",
		0.0, 1.0, time_show_full_text,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


# Called by the dialog player when the 
func finish_fast():
	tween.stop(text_node)
	tween.interpolate_property(text_node, "percent_visible",
		text_node.percent_visible, 1.0, fast_text_speed_per_character,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


# The dialog line was printed, start the waiting time and then finish
# the dialog
func _on_dialog_line_typed(object, key):
	text_node.visible_characters = -1
	$Timer.start(max_time_to_text_disappear)
	$Timer.connect("timeout", self, "_on_dialog_finished")


# Ending the dialog
func _on_dialog_finished():
	current_character.stop_talking()
	emit_signal("dialog_line_finished")
	escoria.dialog_player.is_speaking = false
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	queue_free()
