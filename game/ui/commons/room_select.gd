extends OptionButton

var selected_id = 0
var options_paths = []

func _ready():
	var rooms_folder = "res://game/rooms/"
	var dir = Directory.new()
	var i = 1
	if dir.open(rooms_folder) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				add_item(file_name)
				options_paths.push_back("res://game/rooms/" + file_name + "/" + file_name + ".tscn")
				i += 1
			file_name = dir.get_next()

	else:
		escoria.report_errors("room_select.gd:_ready()", 
			["A problem occurred while opening rooms folder."])
	

func _on_button_pressed():
	var actual_command = ":debug\nchange_scene " + options_paths[selected_id] + "\n"
	
	var errors = []
	var events = escoria.esc_compiler.compile_str(actual_command, errors)
	
	if errors.empty():
		#past_actions.text += str(events)
		var ret = escoria.esc_runner.run_event(events["debug"])

func _on_option_item_selected(index):
	selected_id = index
