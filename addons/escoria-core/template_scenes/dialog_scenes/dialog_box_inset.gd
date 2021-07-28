# A dialog GUI showing a dialog box and character portraits
tool
extends PanelContainer


# Signal emitted when a dialog line has started
signal dialog_line_started

# Signal emitted when a dialog line has finished
signal dialog_line_finished


# The currently speaking character
export(String) var current_character setget set_current_character

# The text speed per character for normal display
export(float, 0.0, 0.3) var text_speed_per_character = 0.1

# The text speed per character if the dialog line is skipped
export(float) var fast_text_speed_per_character = 0.25

# The time to wait before the dialog is finished
export(float) var max_time_to_text_disappear = 1.0


# The node holding the avatar
onready var avatar_node = $MarginContainer/HSplitContainer/VBoxContainer/avatar

# The node holding the player name
onready var name_node = $MarginContainer/HSplitContainer/VBoxContainer/name

# The node showing the text
onready var text_node = $MarginContainer/HSplitContainer/text

# The tween node for text animations
onready var tween = text_node.get_node("Tween")


# Build up the UI
func _ready():
	var centered_position_on_screen = Vector2(
		ProjectSettings.get_setting("display/window/size/width") / 2,
		ProjectSettings.get_setting("display/window/size/height") / 2
	) - rect_size / 2
	rect_position = centered_position_on_screen
	text_node.bbcode_enabled = true
	$MarginContainer/HSplitContainer/text/Tween.connect(
		"tween_completed", 
		self, 
		"_on_dialog_line_typed"
	)


# Switch the current character
#
# #### Parameters
# - name: The name of the current character
func set_current_character(name: String):
	current_character = name
	if $dialog_avatars:
		if $dialog_avatars.has_node(name):
			avatar_node.texture = ($dialog_avatars.get_node(name) as TextureRect).texture
		else:
			avatar_node.texture = null


# Make a character say something
#
# #### Parameters
# - character: The global id of the character speaking
# - line: Line to say
func say(character: String, line: String) :
	show()
	emit_signal("dialog_line_started")
	set_current_character(character)
	
	text_node.bbcode_text = tr(line)
	
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
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	emit_signal("dialog_line_finished")
	queue_free()
	
	
