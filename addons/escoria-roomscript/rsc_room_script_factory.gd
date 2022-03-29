extends Object
class_name RSCRoomScriptFactory


# `path` is a resource path that starts with "res://"
static func from_path(path: String) -> RSCRoomScript:
	var lines = read_file(path)
	return _partition_lines_into_scripts(lines)


# `path` should be a path to a Godot resource
static func read_file(path: String) -> Array:
	var file = File.new()
	var err = file.open(path, File.READ)
	if err:
		escoria.logger.warning("failed to read .room file: %s" % path)
		return []

	var lines = []
	while not file.eof_reached():
		lines.append(file.get_line())
	return lines


static func _partition_lines_into_scripts(lines: Array) -> RSCRoomScript:
	var item_or_event_regex = create_regex("^(item|event)\\s+([\\w-]+)\\s*\\{$")
	var close_block_regex = create_regex("^\\}$")

	var items = {}
	var events = ESCScript.new()

	var current_event = null
	var current_item = null
	var current_block_lines = null

	for line in lines:
		if current_item != null || current_event != null:
			if close_block_regex.search(line):
				if current_item != null:
					var script = escoria.esc_compiler.compile(current_block_lines)
					items[current_item] = script
				else:
					var script = escoria.esc_compiler.compile([':' + current_event] + current_block_lines)
					# script.events should contain exactly one item.
					var event = script.events.get(current_event)
					assert(event != null && script.events.size() == 1, "events should have exactly one event: %s" % current_event)
					events.events[current_event] = event

				current_event = null
				current_item = null
				current_block_lines = null
			else:
				current_block_lines.append(line)
		else:
			var re_match = item_or_event_regex.search(line)
			if re_match:
				var block_type = re_match.get_string(1)
				if block_type == 'item':
					current_item = re_match.get_string(2)
					escoria.logger.debug("item in roomfile: %s" % current_item)
				elif block_type == 'event':
					current_event = re_match.get_string(2)
					escoria.logger.debug("event in roomfile: %s" % current_event)
				else:
					escoria.logger.error("ignoring unknown type: %s" % block_type)
					continue
				current_block_lines = []

	return RSCRoomScript.new(events, items)


static func create_regex(pattern: String) -> RegEx:
	var re = RegEx.new()
	var err = re.compile(pattern)
	if not err:
		return re
	else:
		assert(false, "could not compile regex %s" % pattern)
		return null
