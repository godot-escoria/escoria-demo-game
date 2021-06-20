# A debug window which can run esc commands
extends WindowDialog


# Reference to the past actions display
onready var past_actions = $VBoxContainer/past_actions

# Reference to the command input
onready var command = $VBoxContainer/command


# Run a command
#
# #### Parameters
#
# - p_command_str: Command to execute
func _on_command_text_entered(p_command_str : String):
	if p_command_str.empty():
		return
	
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
		escoria.event_manager.queue_event(script.events["debug"])
		var ret = yield(escoria.event_manager, "event_finished")
		while ret[1] != "debug":
			ret = yield(escoria.event_manager, "event_finished")
		past_actions.text += "Returned code: %d" % ret[0]


# Set the focus to the command
func _on_esc_prompt_popup_about_to_show():
	command.grab_focus()
