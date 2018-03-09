
var commands = {
	"set_global": { "min_args": 2, "types": [TYPE_STRING, TYPE_BOOL] },
	"set_globals": { "min_args": 2, "types": [TYPE_STRING, TYPE_BOOL] },
	"debug": { "min_args": 1 },
	"anim": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_BOOL, TYPE_BOOL, TYPE_BOOL] },
	"set_state": { "min_args": 2 },
	"say": { "min_args": 2 },
	"?": { "alias": "dialog"},
	"cut_scene": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_BOOL, TYPE_BOOL, TYPE_BOOL] },
	">": { "alias": "branch"},
	"inventory_add": { "min_args": 1 },
	"inventory_remove": { "min_args": 1 },
	"inventory_open": { "min_args": 1, "types": [TYPE_BOOL] },
	"set_active": { "min_args": 2, "types": [TYPE_STRING, TYPE_BOOL] },
	"stop": true,
	"repeat": true,
	"wait": true,
	"teleport": { "min_args": 2 },
	"teleport_pos": { "min_args": 3 },
	"walk": { "min_args": 2 },
	"walk_block": { "min_args": 2 },
	"change_scene": { "min_args": 1 },
	"spawn": { "min_args": 1 },
	"%": { "alias": "label", "min_args": 1},
	"jump": { "min_args": 1 },
	"dialog_config": { "min_args": 3, "types": [TYPE_STRING, TYPE_BOOL, TYPE_BOOL] },
	"sched_event": { "min_args": 3, "types": [TYPE_REAL, TYPE_STRING, TYPE_STRING] },
	"custom": { "min_args": 2 },
	"camera_set_target": { "min_args": 1, "types": [TYPE_REAL] },
	"camera_set_pos": { "min_args": 3, "types": [TYPE_REAL, TYPE_INT, TYPE_INT] },
	"camera_set_zoom_height": { "min_args": 1, "types": [TYPE_INT] },
	"camera_zoom_in": { "min_args": 1, "types": [TYPE_REAL] },
	"camera_zoom_out": { "min_args": 0 },
	"autosave": { "min_args": 0 },
	"queue_resource": { "min_args": 1, "types": [TYPE_STRING, TYPE_BOOL] },
	"queue_animation": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING, TYPE_BOOL] },
	"game_over": { "min_args": 1, "types": [TYPE_BOOL] },
}


func check_command(cmd, state, errors):
	if !(cmd.name in commands):
		errors.push_back("line "+str(state.line_count)+": command "+cmd.name+" not valid.")
		return false

	var cmd_data = commands[cmd.name]
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
					errors.push_back("line "+str(state.line_count)+": Invalid parameter "+str(i)+" for command "+cmd.name+". Must be 'true' or 'false'.")
					ret = false
			if t == TYPE_INT:
				cmd.params[i] = int(cmd.params[i])
			if t == TYPE_REAL:
				cmd.params[i] = float(cmd.params[i])
			i+=1

	return ret

func read_line(state):
	while true:
		if _eof_reached(state.file):
			state.line = null
			return
		else:
			state.line = _get_line(state.file)
			state.line_count += 1
		if !is_comment(state.line):
			return

func is_comment(line):
	for i in range(0, line.length()):
		var c = line[i]
		if c == "#":
			return true
		if c != " " && c != "\t":
			return false
	return true

func get_indent(line):
	for i in range(0, line.length()):
		if line[i] != " " && line[i] != "\t":
			return i

func is_event(line):
	var trimmed = trim(line)
	if trimmed.find(":") == 0:
		return trimmed.substr(1, trimmed.length()-1)
	return false

func is_flags(tk):
	var trimmed = trim(tk)
	if trimmed.find("[") == 0 && trimmed.find("]") == trimmed.length()-1:
		return true
	return false

func add_level(state, level, errors):
	read_line(state)
	while typeof(state.line) != typeof(null):
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

func add_dialog(state, level, errors):
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
		var read = read_dialog_option(state, level, errors)

func get_token(line, p_from, line_count, errors):
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

func trim(p_str):
	while p_str.length() && (p_str[0] == " " || p_str[0] == "\t"):
		p_str = p_str.substr(1, p_str.length()-1)
	while p_str.length() && p_str[p_str.length()-1] == " " || p_str[p_str.length()-1] == "\t":
		p_str = p_str.substr(0, p_str.length()-1)

	if p_str[0] == "\"":
		p_str = p_str.substr(1, p_str.length()-1)
	if p_str[p_str.length()-1] == "\"":
		p_str = p_str.substr(0, p_str.length()-1)
	return p_str



func parse_flags(p_flags, flags_list, if_true, if_false, if_inv, if_not_inv):
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
			flag = flag.substr(1, flag.length()-1)
			if flag.find("inv-") == -1:
				if_false.push_back(trim(flag))
			else:
				if_not_inv.push_back(trim(flag).substr(4, flag.length()-1))
		else:
			list.push_back(false)
			if flag.find("inv-") == 0:
				if_inv.push_back(trim(flag).substr(4, flag.length()-1))
			else:
				if_true.push_back(trim(flag))
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
		#printt("adding flag ", list)
		flags_list.push_back(list)
		if next == -1:
			return
		from = next+1

func read_dialog_option(state, level, errors):
	var tk_end = get_token(state.line, 0, state.line_count, errors)
	var tk = trim(state.line.substr(0, tk_end))
	if tk != "*" && tk != "-":
		errors.append("line "+str(state.line_count)+": Ivalid dialog option")
		read_line(state)
		return false
	tk_end += 1
	var q_end = state.line.find("[", tk_end)
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
		#printt("parsing flags ", q_flags, state.line)
		var if_true = []
		var if_false = []
		var if_inv = []
		var if_not_inv = []
		var flag_list = []
		parse_flags(q_flags, flag_list, if_true, if_false, if_inv, if_not_inv)
		if if_true.size():
			cmd.if_true = if_true
		if if_false.size():
			cmd.if_false = if_false
		if if_inv.size():
			cmd.if_inv = if_inv
		if if_not_inv.size():
			cmd.if_not_inv = if_inv
		if flag_list.size():
			cmd.flags = flag_list

	state.indent += 1
	add_level(state, cmd.params[1], errors)
	state.indent -= 1

	level.push_back(cmd)

func read_cmd(state, level, errors):
	var params = []
	var from = 0
	var tk_end = get_token(state.line, from, state.line_count, errors)
	var if_true = []
	var if_false = []
	var if_inv = []
	var if_not_inv = []
	var flags = []
	while tk_end != -1:
		var tk = trim(state.line.substr(from, tk_end - from))
		from = tk_end + 1
		if is_flags(tk):
			parse_flags(tk, flags, if_true, if_false, if_inv, if_not_inv)
		else:
			params.push_back(tk)
		tk_end = get_token(state.line, from, state.line_count, errors)

	if params.size() == 0:
		errors.append("line "+str(state.line_count)+": Invalid command.")
		read_line(state)
		return

	var cmd = {"name": params[0]}

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
		cmd.params = params
		read_line(state)

	if if_true.size():
		cmd.if_true = if_true
	if if_false.size():
		cmd.if_false = if_false
	if if_inv.size():
		cmd.if_inv = if_inv
	if if_not_inv.size():
		cmd.if_not_inv = if_inv
	if flags.size():
		cmd.flags = flags

	var valid = check_command(cmd, state, errors)
	if valid:
		level.push_back(cmd)

func read_events(f, ret, errors):

	var state = { "file": f, "line": _get_line(f), "indent": 0, "line_count": 0 }

	while typeof(state.line) != typeof(null):
		if is_comment(state.line):
			read_line(state)
			continue
		var ev = is_event(state.line)
		if typeof(ev) != typeof(null):
			var level = []
			var abort = add_level(state, level, errors)
			ret[ev] = level
			if abort:
				return abort

func _get_line(f):
	if typeof(f) == typeof({}):
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

func compile_str(p_str, errors):
	var f = { "line": 0, "lines": p_str.split("\n") }

	#printt("esc compile str ", f)

	var ret = {}
	read_events(f, ret, errors)

	#printt("returning ", p_fname, ret)
	return ret


func compile(p_fname, errors):
	var f = File.new()
	f.open(p_fname, File.READ)
	if !f.is_open():
		return {}

	var ret = {}
	read_events(f, ret, errors)

	#printt("returning ", p_fname, ret)
	return ret
