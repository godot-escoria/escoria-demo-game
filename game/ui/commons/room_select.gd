extends OptionButton

var selected_id = 0
var options_paths = []

func _ready():
	var rooms_folder = "res://game/rooms/"
	var dir = Directory.new()
	
	if dir.open(rooms_folder) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				add_item(file_name)
				options_paths.push_back("res://game/rooms/" + file_name + "/" + 
					file_name + ".tscn")
			file_name = dir.get_next()

	else:
		escoria.logger.report_errors("room_select.gd:_ready()", 
			["A problem occurred while opening rooms folder."])
	

func _on_button_pressed():
	
	var script = escoria.esc_compiler.compile([
		":debug",
		"change_scene %s" % options_paths[selected_id]
	])
	
	escoria.event_manager.queue_event(script.events['debug'])

func _on_option_item_selected(index):
	selected_id = index
