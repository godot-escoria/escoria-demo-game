extends Node
"""
ESC files:
Lines beginning with ":" such as :push, :say are EVENTS.
Lines in between are usually the ESC API functions calls. They are called COMMANDS.


Steps
 compile_script(path/to/esc) : called once
 	> compile(path/to/esc, errors) : called once
		> read_events() : called once
		>	create an ESCState, initialized with 1st line
		> 	for each line in ESCState that corresponds to an event (:event), create a new level
			> add_level(state, level, errors)
				> for each state.line that belongs to same group (same indentation), create a command
					> read_cmd(state, level, errors)
					> get the token in state.line : this is the actual command (say, teleport, etc.)
					> get the parameters next to the token
					> create an ESCCommand, check it and push it into level array
			> create an ESCEvent with the level created
			> add it to the returned Dictionary of events
In the end, the ESCState has read all lines in the file and is deleted
Returned value is a Dictionary { event name : ESCEvent}
And ESCEvent.level is an array of ESCCommand
"""



var commands = {
	"accept_input": { "min_args": 1, "types": [TYPE_STRING] },
	"autosave": { "min_args": 0 },
	"anim": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_BOOL, TYPE_BOOL, TYPE_BOOL] },
	"camera_push": { "min_args": 1, "types": [TYPE_STRING] },
	"camera_set_drag_margin_enabled": { "min_args": 2, "types": [TYPE_BOOL, TYPE_BOOL] },
	"camera_set_limits": { "min_args": 1, "types": [TYPE_INT]},
	"camera_set_pos": { "min_args": 3, "types": [TYPE_REAL, TYPE_INT, TYPE_INT] },
	"camera_set_target": { "min_args": 1, "types": [TYPE_REAL] },
	"camera_set_zoom": { "min_args": 1, "types": [TYPE_REAL] },
	"camera_set_zoom_height": { "min_args": 1, "types": [TYPE_INT] },
	"camera_shift": { "min_args": 2, "types": [TYPE_INT, TYPE_INT] },
	"change_scene": { "min_args": 1, "types": [TYPE_STRING, TYPE_BOOL] },
	"custom": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING] },
	"cut_scene": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_BOOL, TYPE_BOOL, TYPE_BOOL] },
	"debug": { "min_args": 1 },
	"dec_global": { "min_args": 2, "types": [TYPE_STRING, TYPE_INT] },
#	"dialog_config": { "min_args": 3, "types": [TYPE_STRING, TYPE_BOOL, TYPE_BOOL] },
	"enable_terrain": { "min_args": 1, "types": [TYPE_STRING]},
	"game_over": { "min_args": 1, "types": [TYPE_BOOL] },
	"inc_global": { "min_args": 2, "types": [TYPE_STRING, TYPE_INT] },
	"inventory_add": { "min_args": 1 },
	"inventory_remove": { "min_args": 1 },
	"inventory_display": { "min_args": 1, "types": [TYPE_BOOL] },
	"jump": { "min_args": 1 },
	"label": { "min_args": 1 },
	"play_snd": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_BOOL] },
	"queue_animation": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_BOOL] },
	"queue_resource": { "min_args": 1, "types": [TYPE_STRING, TYPE_BOOL] },
	"repeat": true,
	"set_state": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_BOOL] },
	"set_hud_visible": { "min_args": 1, "types": [TYPE_BOOL]},
	"say": { "min_args": 2 },
	"sched_event": { "min_args": 3, "types": [TYPE_REAL, TYPE_STRING, TYPE_STRING] },
	"set_active": { "min_args": 2, "types": [TYPE_STRING, TYPE_BOOL] },
	"set_angle": { "min_args": 2, "types": [TYPE_STRING, TYPE_INT] },
	"set_global": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING] },
	"set_globals": { "min_args": 2, "types": [TYPE_STRING, TYPE_BOOL] },
	"set_interactive": { "min_args": 2, "types": [TYPE_STRING, TYPE_BOOL] },
	"set_speed": { "min_args": 2, "types": [TYPE_STRING, TYPE_INT] },
	"slide": { "min_args": 2 },
	"slide_block": { "min_args": 2 },
	"spawn": { "min_args": 1 },
	"stop": true,
	"superpose_scene": { "min_args": 1, "types": [TYPE_STRING, TYPE_BOOL] },
	"teleport": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_INT] },
	"teleport_pos": { "min_args": 3 },
	"turn_to": { "min_args": 2 },
	"wait": true,
	"walk": { "min_args": 2 },
	"walk_block": { "min_args": 2 },
	"walk_to_pos": { "min_args": 3},
	"walk_to_pos_block": { "min_args": 3},
	
	"%": { "alias": "label", "min_args": 1},
	"?": { "alias": "dialog"},
	"!": { "alias": "end_dialog", "min_args": 0 },
	">": { "alias": "branch"},
}

# Commands that can be called only by the ESC debug prompt
var debug_commands = {
	"get_active": { "min_args": 1, "types": [TYPE_STRING] },
	"get_global": { "min_args": 1, "types": [TYPE_STRING] },
	"get_interactive": { "min_args": 1, "types": [TYPE_STRING] },
	"get_state": { "min_args": 1, "types": [TYPE_STRING] },
}

# Loads a Dictionary of actions from a file, given its path.
func load_esc_file(esc_file_path : String) -> Dictionary:
	var f = File.new()
	if !f.file_exists(esc_file_path):
		escoria.logger.report_errors("esc_compiler.gd:load_esc_file()", ["File " + esc_file_path + " not found."])
		return {}
	return compile_script(esc_file_path)

# Loads the parameter script file. Can be either GDScript of ESC type.
# Returns the Dictionary of actions loaded from the file.
func compile_script(p_path : String) -> Dictionary:
	var ev_table
	# Script is GDScript
	if p_path.find(".gd") != -1:
		var res = ResourceLoader.load(p_path)
		if res == null:
			return {}
		ev_table = res.new().get_events()
	else: # Script is ESC
		var errors = []
		ev_table = compile(p_path, errors)
		if errors.size() > 0:
			escoria.logger.call_deferred("report_errors", p_path, errors)
	return ev_table
	
func check_command(commands_list : Dictionary, cmd : esctypes.ESCCommand, state : esctypes.ESCState, errors : Array):
	if !(cmd.name in commands_list):
		errors.push_back("line "+str(state.line_count)+": command "+cmd.name+" not valid.")
		return false

	var cmd_data = commands_list[cmd.name]
	if typeof(cmd_data) == TYPE_BOOL:
		return true

	if "alias" in cmd_data:
		cmd.name = cmd_data.alias

	if "min_args" in cmd_data:
		if cmd.params.size() < cmd_data.min_args:
			errors.push_back("line "+str(state.line_count)+": command "+cmd.name+" takes "+str(cmd_data.min_args)+" parameters ("+str(cmd.params.size())+" were given).")
			return false

	var ret = true
	if "types" in cmd_data:
		var i = 0
		for t in cmd_data.types:
			if i >= cmd.params.size():
				break
			if t == TYPE_BOOL:
				if cmd.params[i] == "true":
					cmd.params[i] = true
				elif cmd.params[i] == "false":
					cmd.params[i] = false
				else:
					errors.push_back("line " + str(state.line_count) + ": Invalid parameter " + cmd.params[i] + " for command " + cmd.name + ". Must be 'true' or 'false'.")
					ret = false
			if t == TYPE_INT:
				if not cmd.params[i].is_valid_integer():
					errors.push_back("line " + str(state.line_count) + ": Invalid parameter " + cmd.params[i] + " for command " + cmd.name + ". Expected integer.")
				cmd.params[i] = int(cmd.params[i])
			if t == TYPE_REAL:
				if not cmd.params[i].is_valid_float():
					errors.push_back("line " + str(state.line_count) + ": Invalid parameter " + cmd.params[i] + " for command " + cmd.name + ". Expected float.")
				cmd.params[i] = float(cmd.params[i])
			i+=1
	return ret

# Check that the given command exists and respects the right number of parameters
func check_normal_command(cmd : esctypes.ESCCommand, state : esctypes.ESCState, errors : Array):
	return check_command(commands, cmd, state, errors)

func check_debug_command(cmd : esctypes.ESCCommand, state : esctypes.ESCState, errors : Array):
	return check_command(debug_commands, cmd, state, errors)

# Fills the given "state" with the next line read from the file
func read_line(state : esctypes.ESCState) -> void:
	while true:
		if _eof_reached(state.file):
			state.line = null
			return
		else:
			state.line = _get_line(state.file)
			state.line_count += 1
		if !is_comment(state.line):
			return

# Returns true if line is a comment (starting with #)
func is_comment(line : String) -> bool:
	for i in range(0, line.length()):
		var c = line[i]
		if c == "#":
			return true
		if c != " " && c != "\t":
			return false
	return true

# Returns the position of the first non-blank character in given line string
func get_indent(line : String):
	for i in range(0, line.length()):
		if line[i] != " " && line[i] != "\t":
			return i

# If the given line string is a event (begins with ":"), returns its name
# Else, return false
func is_event(line : String):
	var trimmed = trim(line)
	if trimmed.find(":") == 0:
		return trimmed.substr(1, trimmed.length()-1)
	return false

# Returns true if the given string is a flag (ie. "[.+]")
func is_flags(tk : String) -> bool:
	var trimmed = trim(tk)
	if trimmed.find("[") == 0 && trimmed.find("]") == trimmed.length()-1:
		return true
	return false

# Reads each line contained in the state (ESCState) (updates state.line)
# While the new line belongs to the same group, creates an ESCCommand from the current state
func add_level(state : esctypes.ESCState, level : Array, errors : Array):
	read_line(state)
	while state.line != null:
		if is_event(state.line):
			return
		var ind_level = get_indent(state.line)
		if ind_level < state.indent:
			return
		if ind_level > state.indent:
			errors.push_back("line "+str(state.line_count)+": invalid indentation for group")
			read_line(state)
			continue

		read_cmd(state, level, errors)

func add_dialog(state : esctypes.ESCState, level : Array, errors : Array):
	read_line(state)

	while typeof(state.line) != typeof(null):
		if is_event(state.line):
			return

		var ind_level = get_indent(state.line)

		if ind_level < state.indent:
			return

		if ind_level > state.indent:
			errors.push_back("line "+str(state.line_count)+": invalid indentation for dialog")
			read_line(state)
			continue

		read_dialog_option(state, level, errors)

func get_token(line : String, p_from : int, line_count : int, errors : Array) -> int:
	while p_from < line.length():
		if line[p_from] == " " || line[p_from] == "\t":
			p_from += 1
		else:
			break
	if p_from >= line.length():
		return -1
	var tk_end
	if line[p_from] == "[":
		tk_end = line.find("]", p_from)
		if tk_end == -1:
			errors.push_back("line "+str(line_count)+": unterminated flags")
		tk_end += 1
	elif line[p_from] == "\"":
		tk_end = line.find("\"", p_from+1)
		if tk_end == -1:
			errors.push_back("line "+str(line_count)+": unterminated quotes, line '"+line+"'")
	else:
		tk_end = p_from
		while tk_end < line.length():
			if line[tk_end] == ":":
				var ntk = get_token(line, tk_end+1, line_count, errors)
				tk_end = ntk
				break
			if line[tk_end] == " " || line[tk_end] == "\t":
				break
			tk_end += 1
	return tk_end

# Remove blank characters around p_str
func trim(p_str : String) -> String:
	while p_str.length() && (p_str[0] == " " || p_str[0] == "\t"):
		p_str = p_str.substr(1, p_str.length()-1)
	while p_str.length() && p_str[p_str.length()-1] == " " || p_str[p_str.length()-1] == "\t":
		p_str = p_str.substr(0, p_str.length()-1)

	if p_str[0] == "\"":
		p_str = p_str.substr(1, p_str.length()-1)
	if p_str[p_str.length()-1] == "\"":
		p_str = p_str.substr(0, p_str.length()-1)
	return p_str

# Parses a flags string (usually defined by '[.*]') and fills the flags_list array
# and ifs variable (Dictionary containing all ifs conditions)
func parse_flags(p_flags : String, flags_list : Array, ifs : Dictionary):
	var from = 1
	while true:
		var next = p_flags.find(",", from)
		var flag
		if next == -1:
			flag = p_flags.substr(from, (p_flags.length()-1) - from)
		else:
			flag = p_flags.substr(from, next - from)
		flag = trim(flag)
		var list = []

		if flag[0] == "!":
			list.push_back(true)
			flag = trim(flag.substr(1, flag.length()-1))
			if flag.find("inv-") == 0:
				ifs["if_not_inv"].push_back(trim(flag).substr(4, flag.length()-1))
			elif flag.find("a/") == 0:
				ifs["if_not_active"].push_back(trim(flag).substr(2, flag.length() - 1))
			elif flag.substr(0, 3) in ["eq ", "gt ", "lt "]:
				var elems = flag.split(" ", true, 2)
				var comparison = "ne" if elems[0] == "eq" else "le" if elems[0] == "gt" else "ge"
				ifs["if_" + comparison].push_back([elems[1], elems[2]])
			else:
				ifs["if_false"].push_back(trim(flag))
		else:
			list.push_back(false)
			if flag.find("inv-") == 0:
				ifs["if_inv"].push_back(trim(flag).substr(4, flag.length()-1))
			elif flag.find("a/") == 0:
				ifs["if_active"].push_back(trim(flag).substr(2, flag.length() - 1))
			elif flag.substr(0, 3) in ["eq ", "gt ", "lt "]:
				var elems = flag.split(" ", true, 2)
				ifs["if_" + elems[0]].push_back([elems[1], elems[2]])
			else:
				ifs["if_true"].push_back(trim(flag))

		if flag.find(":") >= 0:
			var pos = flag.substr(0, flag.find(":"))
			var inv = flag.substr(0, pos)
			inv = trim(inv)
			list.push_back(inv)
			flag = flag.substr(pos, flag.length() - pos)
		elif flag.find("inv-") == 0:
			flag = trim(flag).substr(4, flag.length()-1)
			list.push_back("i")
		else:
			list.push_back("g")

		list.push_back(trim(flag))
		# printt("adding flag ", list)
		flags_list.push_back(list)
		if next == -1:
			return
		from = next+1

func read_dialog_option(state : esctypes.ESCState, level : Array, errors : Array):
	var tk_end = get_token(state.line, 0, state.line_count, errors)
	var tk = trim(state.line.substr(0, tk_end))
	if tk != "*" && tk != "-":
		errors.append("line "+str(state.line_count)+": Invalid dialog option")
		read_line(state)
		return

	# Remove inline comments
	var comment_idx = state.line.find("#")
	if comment_idx > -1:
		state.line = state.line.substr(0, comment_idx)

	tk_end += 1
	# var c_start = state.line.find("\"", 0)
	var c_end = state.line.find_last("\"")
	var q_end = state.line.find("[", c_end)
	var q_flags = null
	#printt("flags before", q_flags)
	if q_end == -1:
		q_end = state.line.length()
	else:
		var f_end = state.line.find("]", q_end)
		if f_end == -1:
			errors.append("line "+str(state.line_count)+": unterminated flags")
		else:
			f_end += 1
			q_flags = state.line.substr(q_end, f_end - q_end)
	var question = trim(state.line.substr(tk_end, q_end - tk_end))
	var cmd = { "name": "*", "params": [question, []] }

	if q_flags:
		var ifs = {
			"if_true": [], "if_false": [], "if_inv": [], "if_not_inv": [],
			"if_active": [], "if_not_active": [],
			"if_eq": [], "if_ne": [], # string and integer comparison
			"if_gt": [], "if_ge": [], "if_lt": [], "if_le": [] # integer comparison
		}
		var flag_list = []
		parse_flags(q_flags, flag_list, ifs)
		for key in ifs:
			if ifs[key].size():
				cmd.conditions[key] = ifs[key]
		if flag_list.size():
			cmd.flags = flag_list

	state.indent += 1
	add_level(state, cmd.params[1], errors)
	state.indent -= 1

	level.push_back(cmd)

# Read an ESCState and converts it to ESCCommand
# then puts it into level (Array of ESCCommand)
func read_cmd(state : esctypes.ESCState, level : Array, errors : Array):
	var params = []
	var from = 0
	var tk_end = get_token(state.line, from, state.line_count, errors)
	var ifs = {
		"if_true": [], "if_false": [], "if_inv": [], "if_not_inv": [],
		"if_active": [], "if_not_active": [],
		"if_eq": [], "if_ne": [], # string and integer comparison
		"if_gt": [], "if_ge": [], "if_lt": [], "if_le": [] # integer comparison
	}
	var flags = []
	while tk_end != -1:
		var tk = trim(state.line.substr(from, tk_end - from))
		from = tk_end + 1
		if is_flags(tk):
			parse_flags(tk, flags, ifs)
		else:
			params.push_back(tk)
		tk_end = get_token(state.line, from, state.line_count, errors)

	if params.size() == 0:
		errors.append("line "+str(state.line_count)+": Invalid command.")
		read_line(state)
		return

	var cmd = esctypes.ESCCommand.new(params[0])

	if params[0] == ">":
		cmd.params = []
		state.indent += 1
		add_level(state, cmd.params, errors)
		state.indent -= 1
	elif params[0] == "?":
		params.remove(0)
		var dialog_params = []
		state.indent += 1
		add_dialog(state, dialog_params, errors)
		cmd.params = params
		cmd.params.insert(0, dialog_params)
		state.indent -= 1
	elif params[0] == "*":
		errors.push_back("line "+str(state.line_count)+": Invalid command: dialog option outside dialog")
		read_line(state)
		return
	else:
		params.remove(0)

		# Remove inline comments
		var comment_idx = params.find("#")
		if comment_idx > -1:
			params.resize(comment_idx)

		cmd.params = params
		read_line(state)

	for key in ifs:
		if ifs[key].size():
			cmd.conditions[key] = ifs[key]
			
	if flags.size():
		cmd.flags = flags
		
	var errors_before = errors.duplicate()
	var valid = check_normal_command(cmd, state, errors)
	if valid:
		level.push_back(cmd)
	else:
		var debug_valid = check_debug_command(cmd, state, errors)
		if debug_valid:
			errors.clear()
			level.push_back(cmd)

# Read events from f (Dictionary or File) into ret Dictionary
func read_events(f, ret : Dictionary, errors : Array):
	#var state = { "file": f, "line": _get_line(f), "indent": 0, "line_count": 0 }
	var state = esctypes.ESCState.new(f, _get_line(f), 0, 0)

	while state.line != null:
		if is_comment(state.line):
			read_line(state)
			continue
		var ev = is_event(state.line)
		if typeof(ev) != typeof(null):
			var level = []
			var abort = add_level(state, level, errors)
			var ev_flags = []
			if ev is String:
				if "|" in ev:
					var ev_split = ev.split("|", true, 1)
					ev = ev_split[0]
					ev = ev.strip_edges()
					if ev_split.size() > 1:
						ev_split[1] = ev_split[1].strip_edges()
						ev_flags = ev_split[1].split(" ")
	
				ret[ev] = esctypes.ESCEvent.new(ev, level, Array(ev_flags))
				if abort:
					return abort

# If f is a File, returns the next line as String (or null)
# If f is a Dictionary, returns the next line from f.lines 
func _get_line(f):
	if f is Dictionary:
		if f.line >= f.lines.size():
			return null
		var line = f.lines[f.line]
		f.line += 1
		#printt("reading line ", line)
		return line
	else:
		return f.get_line()

func _eof_reached(f):
	if typeof(f) == typeof({}):
		return f.line >= f.lines.size()
	else:
		return f.eof_reached()

func compile_str(p_str : String, errors : Array):
	var f = { "line": 0, "lines": p_str.split("\n") }

	#printt("esc compile str ", f)

	var ret = {}
	read_events(f, ret, errors)

	#printt("returning ", p_fname, ret)
	return ret

# Returns a Dictionary of events read from p_fname filename
func compile(p_fname : String, errors : Array) -> Dictionary:
	var f = File.new()
	f.open(p_fname, File.READ)
	if !f.is_open():
		return {}

	var ret = {}
	read_events(f, ret, errors)

	#printt("returning ", p_fname, ret)
	return ret
