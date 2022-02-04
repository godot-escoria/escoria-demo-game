# Compiler of the ESC language
extends Object
class_name ESCCompiler


# A RegEx for comment lines
const COMMENT_REGEX = '^\\s*#.*$'

# A RegEx for empty lines
const EMPTY_REGEX = '^\\s*$'

# A RegEx for finding out the indent of a line
const INDENT_REGEX_GROUP = "indent"
const INDENT_REGEX = '^(?<%s>\\s*)' % INDENT_REGEX_GROUP


# RegEx objects for use by the ESC compiler
var _comment_regex
var _empty_regex
var _indent_regex
var _event_regex
var _command_regex
var _dialog_regex
var _dialog_end_regex
var _dialog_option_regex
var _group_regex

# The currently compiled event
var _current_event = null

# A stack of groups currently compiling
var _groups_stack = []

# A stack of dialogs currently compiling
var _dialogs_stack = []

# A stack of dialog options currently compiling
var _dialogs_option_stack = []

# A pointer to the current container (group, dialog option)
# that should get the current command
var _command_container = []

# The currently identified indent
var _current_indent = 0


func _init():
	# Assure command list preference
	# (we use ProjectSettings instead of escoria.project_settings_manager
	# here because this is called from escoria._init())
	if not ProjectSettings.has_setting("escoria/esc/command_paths"):
		ProjectSettings.set_setting("escoria/esc/command_paths", [
			"res://addons/escoria-core/game/core-scripts/esc/commands"
		])
		var property_info = {
			"name": "escoria/esc/command_paths",
			"type": TYPE_STRING_ARRAY
		}
		ProjectSettings.add_property_info(property_info)
	
	# Compile all regex objects just once
	_comment_regex = RegEx.new()
	_comment_regex.compile(COMMENT_REGEX)
	_empty_regex = RegEx.new()
	_empty_regex.compile(EMPTY_REGEX)
	_indent_regex = RegEx.new()
	_indent_regex.compile(INDENT_REGEX)
	
	_event_regex = RegEx.new()
	_event_regex.compile(ESCEvent.REGEX)
	_command_regex = RegEx.new()
	_command_regex.compile(ESCCommand.REGEX)
	_dialog_regex = RegEx.new()
	_dialog_regex.compile(ESCDialog.REGEX)
	_dialog_end_regex = RegEx.new()
	_dialog_end_regex.compile(ESCDialog.END_REGEX)
	_dialog_option_regex = RegEx.new()
	_dialog_option_regex.compile(ESCDialogOption.REGEX)
	_group_regex = RegEx.new()
	_group_regex.compile(ESCGroup.REGEX)


# Load an ESC file from a file resource
func load_esc_file(path: String) -> ESCScript:
	escoria.logger.debug("Parsing file %s" % path)
	if File.new().file_exists(path):
		var file = File.new()
		file.open(path, File.READ)
		var lines = []
		while not file.eof_reached():
			lines.append(file.get_line())
		return self.compile(lines)
	else:
		escoria.logger.report_errors(
			"Can not find ESC file",
			[
				"File %s could not be found" % path
			]
		)
		return null


# Compiles an array of ESC script strings to an ESCScript
func compile(lines: Array) -> ESCScript:
	var script = ESCScript.new()
	if lines.size() > 0:
		var events = self._compile(lines)
		for event in events:
			script.events[event.name] = event
			
	return script


# Compile an array of ESC script lines into an array of ESC objects
func _compile(lines: Array) -> Array:
	var returned = []
	
	while lines.size() > 0:
		var line = lines.pop_front()
		escoria.logger.trace("Parsing line %s" % line)
		if _comment_regex.search(line) or _empty_regex.search(line):
			# Ignore comments and empty lines
			escoria.logger.trace("Line is empty or a comment. Skipping.")
			continue
		var indent = \
				escoria.utils.get_re_group(
					_indent_regex.search(line), 
					INDENT_REGEX_GROUP
				).length()
		
		if _event_regex.search(line):
			var event = ESCEvent.new(line)
			escoria.logger.trace("Line is the event %s" % event.name)
			var event_lines = []
			while lines.size() > 0:
				var next_line = lines.pop_front()
				if not _event_regex.search(next_line):
					event_lines.append(next_line)
				else:
					lines.push_front(next_line)
					break
			if event_lines.size() > 0:
				escoria.logger.trace(
					"Compiling the next %d lines into the event" % \
							event_lines.size()
				)
				event.statements = self._compile(event_lines)
			returned.append(event)
		elif _group_regex.search(line):
			var group = ESCGroup.new(line)
			escoria.logger.trace("Line is a group")
			var group_lines = []
			while lines.size() > 0:
				var next_line = lines.pop_front()
				if _comment_regex.search(next_line) or \
						_empty_regex.search(next_line):
					continue
				var next_line_indent = \
						escoria.utils.get_re_group(
							_indent_regex.search(next_line), 
							INDENT_REGEX_GROUP
						).length()
				if next_line_indent > indent:
					group_lines.append(next_line)
				else:
					lines.push_front(next_line)
					break
			if group_lines.size() > 0:
				escoria.logger.trace(
					"Compiling the next %d lines into the group" % \
							group_lines.size()
				)
				group.statements = self._compile(group_lines)
			returned.append(group)
		elif _dialog_regex.search(line):
			var dialog = ESCDialog.new()
			dialog.load_string(line)
			escoria.logger.trace("Line is a dialog")
			var dialog_lines = []
			while lines.size() > 0:
				var next_line = lines.pop_front()
				if _comment_regex.search(next_line) or \
						_empty_regex.search(next_line):
					continue
				var end_line = _dialog_end_regex.search(next_line)
				if end_line and \
						escoria.utils.get_re_group(
							end_line, 
							INDENT_REGEX_GROUP
						).length() == indent:
					break
				else:
					dialog_lines.append(next_line)
			if dialog_lines.size() > 0:
				escoria.logger.trace(
					"Compiling the next %d lines into the dialog" % \
							dialog_lines.size()
				)
				dialog.options = self._compile(dialog_lines)
			# Remove the end line from the stack
			lines.pop_front()
			returned.append(dialog)
		elif _dialog_option_regex.search(line):
			var dialog_option = ESCDialogOption.new()
			dialog_option.load_string(line)
			escoria.logger.trace(
				"Line is the dialog option %s" % \
						dialog_option.option
			)
			var dialog_option_lines = []
			while lines.size() > 0:
				var next_line = lines.pop_front()
				if _comment_regex.search(next_line) or \
						_empty_regex.search(next_line):
					continue
				var next_line_indent = \
						escoria.utils.get_re_group(
							_indent_regex.search(next_line), 
							INDENT_REGEX_GROUP
						).length()
				if next_line_indent > indent:
					dialog_option_lines.append(next_line)
				else:
					lines.push_front(next_line)
					break
			if dialog_option_lines.size() > 0:
				escoria.logger.trace(
					"Compiling the next %d lines into the event" % \
							dialog_option_lines.size()
				)
				dialog_option.statements = self._compile(dialog_option_lines)
			returned.append(dialog_option)
		elif _command_regex.search(line):
			var command = ESCCommand.new(line)
			if command.command_exists():
				returned.append(command)
			else:
				escoria.logger.report_errors(
					"Invalid command detected: %s" % command.name,
					[
						"Command implementation not found in any command directory"
					]
				)
		else:
			escoria.logger.report_errors(
				"Invalid ESC line detected",
				[
					"Line couldn't be compiled: %s" % line
				]
			)
	return returned
