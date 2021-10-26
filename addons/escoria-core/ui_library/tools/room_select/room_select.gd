# A small utility to quickly switch to a room while developing
extends OptionButton


# The selected option
var _selected_id = 0


# The path to available rooms
var _options_paths = []


# Build up the list of rooms
func _ready():
	var rooms_folder = ProjectSettings.get_setting(
		"escoria/debug/room_selector_room_dir"
	)
	if rooms_folder == "" or \
		not ProjectSettings.get_setting("escoria/debug/enable_room_selector"):
		return
	var dir = Directory.new()
	var rooms_list: Array = []
	var path = ProjectSettings.globalize_path(rooms_folder)
	if not OS.has_feature("editor"):
		path = OS.get_executable_path().get_base_dir().plus_file(path)
	var tmp = dir.open(path)
	if tmp == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				rooms_list.push_back(file_name)
			file_name = dir.get_next()
		
		rooms_list.sort()
		for room in rooms_list:
			add_item(room)
			_options_paths.push_back("%s/%s/%s.tscn" %[
				rooms_folder,
				room,
				room
			])

	else:
		escoria.logger.report_warnings("room_select.gd:_ready()", 
			["A problem occurred while opening rooms folder."])
	

# Switch to the selected room
func _on_button_pressed():
	escoria.globals_manager.set_global("BYPASS_LAST_SCENE", true, true)
	var script = escoria.esc_compiler.compile([
		":debug",
		"change_scene %s" % _options_paths[_selected_id]
	])
	escoria.event_manager.interrupt_running_event()
	escoria.event_manager.queue_event(script.events['debug'])
	


# A room was selected, store the selection
#
# #### Parameters
# - index: The index of the selected room in the paths list
func _on_option_item_selected(index):
	_selected_id = index
