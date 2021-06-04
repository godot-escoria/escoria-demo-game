tool
extends Control

export(Color, RGB) var color_normal = Color(1.0,1.0,1.0,1.0)
export(Color, RGB) var color_hover = Color(165.0,42.0,42.0, 1.0)
export(Font) var font

var commands

func _ready():
	for c in $ScrollContainer/VBoxContainer.get_children():
		c.queue_free()


func set_answers(options : Array):
	commands = options
	for option in commands:
		var new_answer_label = RichTextLabel.new()
		new_answer_label.text = option.option
		new_answer_label.fit_content_height = true
		new_answer_label.add_font_override("normal_font", font)
		
		$ScrollContainer/VBoxContainer.add_child(new_answer_label)
		new_answer_label.fit_content_height = true
		new_answer_label.connect("focus_entered", self, "_on_answer_focus_entered", [new_answer_label])	# Focus entered
		new_answer_label.connect("focus_exited", self, "_on_answer_focus_exited", [new_answer_label])		# Focus exited
		new_answer_label.connect("mouse_entered", self, "_on_answer_mouse_entered", [new_answer_label])	# Mouse entered
		new_answer_label.connect("mouse_exited", self, "_on_answer_mouse_exited", [new_answer_label])		# Mouse exited
		new_answer_label.connect("gui_input", self, "_on_answer_gui_input", [option]) 			# Clicks

func _on_answer_gui_input(event : InputEvent, answer : ESCDialogOption):
	if event is InputEventMouseButton and event.is_pressed(): 
		escoria.dialog_player.play_dialog_option_chosen(answer)

func _on_answer_mouse_entered(answer_node : Node):
	var text = answer_node.text
	answer_node.clear()
	answer_node.push_color(color_hover.to_html(false))
	answer_node.append_bbcode(text)
	answer_node.pop()

func _on_answer_mouse_exited(answer_node : Node):
	var text = answer_node.text
	answer_node.clear()
	answer_node.push_color(color_normal.to_html(false))
	answer_node.append_bbcode(text)
	answer_node.pop()

func _on_answer_focus_entered(answer_node : Node):
	pass

func _on_answer_focus_exited(answer_node : Node):
	pass
