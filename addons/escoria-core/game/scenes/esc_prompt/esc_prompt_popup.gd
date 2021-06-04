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
	var script = escoria.esc_compiler.compile([
		":debug",
		p_command_str
	])
	
	if script:
		escoria.event_manager.run(script.events["debug"])
		var ret = yield(escoria.event_manager, "event_finished")
		while ret[1] != "debug":
			ret = yield(escoria.event_manager, "event_finished")
		if not ret[0] == ESCExecution.RC_OK:
			past_actions.text += "Returned code: %d" % ret[0]
		

func _on_event_done(event_name : String):
	if event_name == "debug" and !last_event_done:
		last_event_done = true
#		past_actions.text += "\nDone.\n"


func _on_esc_prompt_popup_about_to_show():
	command.grab_focus()
