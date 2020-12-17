extends WindowDialog

onready var past_actions = $VBoxContainer/past_actions
onready var command = $VBoxContainer/command

var last_event_done := true

func _on_command_text_entered(p_command_str : String):
	if p_command_str.empty():
		return
	
	last_event_done = false
	command.text = ""
	past_actions.text += "\n"
	past_actions.text += "# " + p_command_str
	past_actions.text += "\n"
	
	var actual_command = ":debug\n" + p_command_str + "\n"
	
	var errors = []
	var events = escoria.esc_compiler.compile_str(actual_command, errors)
	
	if errors.empty():
		#past_actions.text += str(events)
		var ret = escoria.esc_runner.run_event(events["debug"])
		if ret != null:
			past_actions.text += str(ret)
	else:
		# Display first error only
		past_actions.text += str(errors[0].split(":")[1].strip_edges())
		

func _on_event_done(event_name : String):
	if event_name == "debug" and !last_event_done:
		last_event_done = true
#		past_actions.text += "\nDone.\n"


func _on_esc_prompt_popup_about_to_show():
	command.grab_focus()
