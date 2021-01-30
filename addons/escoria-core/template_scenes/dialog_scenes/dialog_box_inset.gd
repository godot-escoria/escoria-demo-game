tool
extends PanelContainer

signal dialog_line_finished

export(String) var current_character setget set_current_character
onready var avatar_node = $MarginContainer/HSplitContainer/VBoxContainer/avatar
onready var name_node = $MarginContainer/HSplitContainer/VBoxContainer/name
onready var text_node = $MarginContainer/HSplitContainer/text
onready var tween = text_node.get_node("Tween")

export(float, 0.0, 0.3) var text_speed_per_character = 0.1
export(float) var fast_text_speed_per_character = 0.25
export(float) var max_time_to_text_disappear = 1.0

func _ready():
	var centered_position_on_screen = Vector2(
		ProjectSettings.get_setting("display/window/size/width") / 2,
		ProjectSettings.get_setting("display/window/size/height") / 2
	) - rect_size / 2
	rect_position = centered_position_on_screen
	text_node.bbcode_enabled = true
	$MarginContainer/HSplitContainer/text/Tween.connect("tween_completed", self, "_on_dialog_line_typed")
	
func set_current_character(name: String):
	current_character = name
	if $dialog_avatars:
		if $dialog_avatars.has_node(name):
			avatar_node.texture = ($dialog_avatars.get_node(name) as TextureRect).texture
		else:
			avatar_node.texture = null


"""
Make a character say something.

character: global id of the character who speaks
params: Dictionary
	line: line of dialog to say
"""
func say(character : String, params : Dictionary) :
	show()
	set_current_character(character)
	
	if !params["line"]:
		escoria.report_errors("dialog_box_inset.gd:say()", ["No line field in params!"])
		return
	
	text_node.bbcode_text = params["line"]
	
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
	escoria.esc_level_runner.finished()
	escoria.dialog_player.is_speaking = false
	escoria.current_state = escoria.GAME_STATE.DEFAULT
#	emit_signal("dialog_line_finished")
	queue_free()
	
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			finish_fast()
