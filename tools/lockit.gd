extends MainLoop

func _iteration(time):
	return true

func get_input_files(argv):

	var list = []

	if "-esc" in argv:
		for i in range(argv.size()):
			if argv[i] == "-esc":
				list.push_back(argv[i+1])
		return list

	find_esc("", list)

	return list

func find_esc(path, list):

	var loc = path
	if loc == "":
		loc = "."

	var d = Directory.new()
	d.open(loc)
	d.list_dir_begin()
	var f = d.get_next()

	while f != "":
		if f == "." || f == "..":
			f = d.get_next()
			continue
		if d.current_is_dir():
			find_esc(path + f + "/", list)
		else:
			if f.find(".esc") == f.length() - 4:
				list.push_back(path + f)
		f = d.get_next()

	d.list_dir_end()

func trim(p_str):
	while p_str.length() && (p_str[0] == " " || p_str[0] == "\t"):
		p_str = p_str.substr(1, p_str.length()-1)
	while p_str.length() && (p_str[p_str.length()-1] == " " || p_str[p_str.length()-1] == "\t"):
		p_str = p_str.substr(0, p_str.length()-1)

	return p_str

func get_token(line, p_from):
	while p_from < line.length():
		if line[p_from] == " " || line[p_from] == "\t":
			p_from += 1
		else:
			break
	if p_from >= line.length():
		return -1

	var tk_end
	if line[p_from] == "\"":
		tk_end = line.find("\"", p_from+1)
		if tk_end == -1:
			tk_end = line.length()-1
		tk_end += 1
	else:
		tk_end = p_from
		while tk_end < line.length():
			if line[tk_end] == ":":
				var ntk = get_token(line, tk_end+1)
				tk_end = ntk
				break
			if line[tk_end] == " " || line[tk_end] == "\t":
				break
			tk_end += 1
	return tk_end

func process_file(path, ids):

	printt("process file ", path)

	var f = File.new()
	f.open(path, File.READ)
	if !f.is_open():
		print(" ** Failed opening file ", path)
		return

	var fo = File.new()
	var tmp_dst = "esc_tmp_" + str(OS.get_process_id())
	fo.open(tmp_dst, File.WRITE)
	if !fo.is_open():
		print(" ** Failed opening temp file ", tmp_dst, " for ", path)
		f.close()
		return

	var section = ""
	var section_count = 0
	var line_count = 0
	var base = path.get_file().get_basename()

	ids._found.push_back(["file", base])

	var section_ids = []

	while !f.eof_reached():
		var line = f.get_line()
		line_count += 1
		if line == "":
			continue

		if line[0] == "#":
			continue

		if line[0] == ":":
			var end = line.find(" ")
			if end == -1:
				end = line.length()
			section = line.substr(1, end-1)

			var pos = f.get_position()
			section_ids = find_section_ids(f)
			f.seek(pos)

			ids._found.push_back(["section", section])

		else:
			var from = 0
			var first = null
			var args = []
			while true:
				var tk_end
				if args.size() == 1 && args[0] == "*":
					var cond = line.find("[")
					if cond >= 0:
						tk_end = cond - 1
					else:
						tk_end = line.length()
				else:
					tk_end = get_token(line, from)
				if tk_end == -1:
					break

				var next = line.substr(from, tk_end - from)
				next = trim(next)

				if args.size() == 1 && args[0] == "*":
					next = "\""+next+"\""

				if next.find(":\"") != -1:
					section_count += 1
					# already has an id
					var sep = next.find(":")
					var id = next.substr(0, sep)
					var text = next.substr(sep+1, next.length() - sep)
					text = text.substr(1, text.length()-2)

					add_to_ids(ids, id, text, path, line_count, args)

				elif next[0] == "\"": # a string
					section_count += 1
					var text = next.substr(1, next.length()-2)
					var has = has_id(text, ids, args)
					var id
					if has != null:
						id = has
					else:
						id = get_new_id(base, section, section_count, section_ids, args)
					section_ids.push_back(id)

					add_to_ids(ids, id, text, path, line_count, args)

					var line_new = line.substr(0, from+1)
					next = id + ":\"" + text + "\""
					line_new = line_new + next
					var tend = line_new.length()
					line_new = line_new + line.substr(tk_end, line.length() - tk_end)
					tk_end = tend

					line = line_new
				elif next == "*":
					var line_new = line.substr(0, tk_end - 1)
					line = line_new + "-" + line.substr(tk_end, line.length() - tk_end)

				args.push_back(next)

				from = tk_end

		fo.store_line(line)

	f.close()
	fo.close()

	var d = Directory.new()
	d.open(".")
	d.rename(tmp_dst, path+".lockit")

func has_id(text, ids, args):
	if !(text in ids._texts):
		return null

	if args[0] == "say":

		if args[1] in ids._texts[text]:
			return ids._texts[text][args[1]]
		else:
			return null

	else: # match any
		var key = ids._texts[text].keys()[0]
		return ids._texts[text][key]

	return null

func add_to_ids(ids, id, text, path, line_count, args):

	ids._found.push_back(["text", id])

	if id in ids:
		ids[id].files.push_back(path + ":" + str(line_count))
		if text != ids[id].text:
			ids[id].conflicts.push_back([path + ":" + str(line_count), text])

	else:
		ids[id] = { "text": text, "files": [ path + ":" + str(line_count) ], "conflicts": [], "args": args }

	if !(text in ids._texts):
		ids._texts[text] = {}

	if args[0] == "say":
		if !(args[1] in ids._texts[text]):
			ids._texts[text][args[1]] = id
	else:
		ids._texts[text]["dialog"] = id

func get_new_id(base, section, section_count, section_ids, args):
	var r = base + "_" + section + "_" + str(section_count)
	var count = 0
	var ret = r
	while ret in section_ids:
		count += 1
		ret = r + "." + str(count)

	return ret

func find_section_ids(f):
	var sec_ids = []

	while !f.eof_reached():
		var line = f.get_line()
		if line == "":
			continue

		if line[0] == "#":
			continue

		if line[0] == ":":
			break

		var from = 0
		while true:
			var tk_end = get_token(line, from)
			if tk_end == -1:
				break
			var next = line.substr(from, tk_end - from)
			next = trim(next)
			if next.find(":\"") != -1:
				var sep = next.find(":")
				var id = next.substr(0, sep)
				sec_ids.push_back(id)

			from = tk_end

	return sec_ids

func write_csv(out, ids):
	var f = File.new()
	f.open(out, File.WRITE)

	var last_type = ""

	for id in ids._found:

		if id[0] == "file":
			f.store_string("\n#,")
			f.store_string("\"" + id[1] + "\",")

		elif id[0] == "section":
			if last_type != "file":
				f.store_string("\n")
			f.store_string("##,")
			f.store_string("\"" + id[1] + "\",\n")

		elif id[0] == "text":

			var t = ids[id[1]]

			f.store_string("\"" + id[1] + "\",")
			f.store_string("\"" + t.text + "\",")

			if t.args[0] == "say":
				f.store_string("\""+t.args[1]+"\",")
			elif t.args[0] == "*":
				f.store_string("\"dialog\",")
			else:
				f.store_string("\""+t.args[0]+"\",")

			f.store_string("\"")
			for tf in t.files:
				f.store_string(tf+", ")
			f.store_string("\", ")

			f.store_string("\"")
			for tf in t.conflicts:
				f.store_string(tf[0] + ":" + tf[1] + ", ")
			f.store_string("\"")

		f.store_string("\n")

		last_type = id[0]

	f.close()

func _initialize():

	var argv = Array(OS.get_cmdline_args())
	while argv.size():
		var p = argv[0]
		argv.remove(0)
		if p in ["-s", "--script"]:
			break

	var out = "strings.csv"
	for i in range(argv.size()):
		if argv[i] == "-out":
			out = argv[i+1]
			break

	var ids = { "_found": [], "_texts": {} }
	var input_files = get_input_files(argv)

	for f in input_files:
		process_file(f, ids)

	write_csv(out, ids)
