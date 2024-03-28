# A debug window which can run esc commands
extends WindowDialog


# Reference to the past actions display
onready var past_actions = $VBoxContainer/past_actions

# Reference to the command input
onready var command = $VBoxContainer/command

# ESC commands kept around for references to their command names.
var _print: PrintCommand

# History of typed commands
var commands_history: PoolStringArray
var commands_history_current_id: int
const COMMANDS_HISTORY_LENGTH: int = 20


func _ready() -> void:
	_print = PrintCommand.new()
	escoria.logger.connect("error_message", self, "_on_error_message")


func _input(event: InputEvent):
	if event.is_pressed() and event is InputEventKey:
		if (event as InputEventKey).scancode == KEY_UP and not commands_history.empty():
			commands_history_current_id -= 1
			if commands_history_current_id < 0:
				commands_history_current_id = 0
			command.text = commands_history[commands_history_current_id]
			command.call_deferred("grab_focus")
		if (event as InputEventKey).scancode == KEY_DOWN and not commands_history.empty():
			commands_history_current_id += 1
			if commands_history_current_id > commands_history.size() - 1:
				commands_history_current_id = commands_history.size() - 1
			command.text = commands_history[commands_history_current_id]
			command.call_deferred("grab_focus")


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
	
	_historize_command(p_command_str)
	
	if p_command_str in ["history", "hist"]:
		for ch in commands_history:
			past_actions.text += ch + "\n"
		return

	var errors = []
	escoria.logger.dont_assert = true
	var script = escoria.esc_compiler.compile([
			"%s%s" % [ESCEvent.PREFIX, _print.get_command_name()],
			p_command_str
		],
		get_class()
	)

	if script:
		escoria.logger.dont_assert = true
		escoria.event_manager.queue_event(script.events[escoria.event_manager.EVENT_PRINT])
		var ret = yield(escoria.event_manager, "event_finished")
		while ret[1] != _print.get_command_name():
			ret = yield(escoria.event_manager, "event_finished")
		past_actions.text += "Returned code: %d" % ret[0]
	
	past_actions.scroll_vertical = past_actions.get_line_count()


# Set the focus to the command
func _on_esc_prompt_popup_about_to_show():
	command.grab_focus()

func _on_error_message(message) -> void:
	past_actions.text += message + "\n"
	past_actions.scroll_vertical = past_actions.get_line_count()


func _historize_command(p_command: String) -> void:
	commands_history_current_id += 1
	commands_history.append(p_command)
	if commands_history.size() + 1 > COMMANDS_HISTORY_LENGTH:
		commands_history.remove(0)
		commands_history_current_id = COMMANDS_HISTORY_LENGTH - 1
		
