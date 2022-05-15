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
			not ProjectSettings.get_setting(
				"escoria/debug/enable_room_selector"
			):
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
		escoria.logger.warn(
			self,
			"A problem occurred while opening rooms folder %s." % str(path)
		)


# Switch to the selected room
func _on_button_pressed():
	# When next room is loaded, we don't want to consider ESC_LAST_SCENE for
	# automatic transitions.
	# If FORCE_LAST_SCENE_NULL is True when change_scene starts:
	# - ESC_LAST_SCENE is set to empty
	escoria.globals_manager.set_global(
		escoria.room_manager.GLOBAL_FORCE_LAST_SCENE_NULL,
		true,
		true
	)

	var script = escoria.esc_compiler.compile([
		":room_selector",
		"change_scene %s" % _options_paths[_selected_id]
	],
	get_class()
	)
	escoria.event_manager.interrupt()
	escoria.event_manager.queue_event(script.events['room_selector'])



# A room was selected, store the selection
#
# #### Parameters
# - index: The index of the selected room in the paths list
func _on_option_item_selected(index):
	_selected_id = index
