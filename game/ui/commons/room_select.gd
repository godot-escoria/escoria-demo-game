extends OptionButton

var selected_id = 0
var options_paths = []

func _ready():
	var rooms_folder = "res://game/rooms/"
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
			options_paths.push_back("res://game/rooms/" + room + "/" + 
				room + ".tscn")

	else:
		escoria.logger.report_warnings("room_select.gd:_ready()", 
			["A problem occurred while opening rooms folder."])
	

func _on_button_pressed():
	
	var script = escoria.esc_compiler.compile([
		":debug",
		"change_scene %s" % options_paths[selected_id]
	])
	
	escoria.event_manager.queue_event(script.events['debug'])

func _on_option_item_selected(index):
	selected_id = index
