extends RichTextLabel

#signal dialog_line_started
#signal dialog_line_finished

onready var tween = $Tween
onready var text_node = self

export(float, 0.0, 0.3) var text_speed_per_character = 0.1
export(float) var fast_text_speed_per_character = 0.25
export(float) var max_time_to_text_disappear = 2.0

# Current character speaking, to keep track of reference for animation purposes
var current_character


func _ready():
	bbcode_enabled = true
	$Tween.connect("tween_completed", self, "_on_dialog_line_typed")

"""
Make a character say something.

character: global id of the character who speaks
params: Dictionary
	line: line of dialog to say
"""
func say(character : String, params : Dictionary) :
	show()
	
	if !params["line"]:
		escoria.logger.report_errors("dialog_box_inset.gd:say()", ["No line field in params!"])
		return
	
	# Position the RichTextLabel on the character's dialog position, if any.
	current_character = escoria.esc_runner.get_object(character)
	rect_position = current_character.get_node("dialog_position").get_global_transform_with_canvas().origin
	rect_position.x -= rect_size.x / 2
	
	current_character.start_talking()
	
	# Set text color to color set in the actor
	var text_color = current_character.dialog_color
	var text_color_html = text_color.to_html(false)
	
	text_node.bbcode_text = "[center][color=#" + text_color_html + "]".format([text_color_html]) + params["line"] + "[/color][center]"
	
	text_node.percent_visible = 0.0
	var time_show_full_text = text_speed_per_character * len(params["line"])
	
	tween.interpolate_property(text_node, "percent_visible",
		0.0, 1.0, time_show_full_text,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func finish_fast():
	tween.stop(text_node)
	tween.interpolate_property(text_node, "percent_visible",
		text_node.percent_visible, 1.0, fast_text_speed_per_character,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_dialog_line_typed(object, key):
	text_node.visible_characters = -1
	$Timer.start(max_time_to_text_disappear)
	$Timer.connect("timeout", self, "_on_dialog_finished")

func _on_dialog_finished():
	current_character.stop_talking()
	escoria.esc_level_runner.finished()
	escoria.dialog_player.is_speaking = false
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	queue_free()
