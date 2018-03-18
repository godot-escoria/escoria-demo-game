tool
extends VBoxContainer

var location
var filen
var saveb
var openb
var text

var content
var current_file = 'res://test.esc'

var keywords = {#Name: color, 
	":":'ff0000',
	"?":'ff9500',
	"-":'ff9500',
	">": '0f7d00',
	"%": '0f7d00',
	'"': 'ffff00',
	"set_global": 'ffffff',
	"set_globals": 'ffffff',
	"debug": 'ffffff',
	"anim": 'ffffff',
	"set_state": 'ffffff',
	"say": 'ffffff',
	"cut_scene": 'ffffff',
	"inventory_add": 'ffffff',
	"inventory_remove": 'ffffff',
	"inventory_open": 'ffffff',
	"set_active": 'ffffff',
	"stop": 'ffffff',
	"repeat": 'ffffff',
	"wait": 'ffffff',
	"teleport": 'ffffff',
	"teleport_pos": 'ffffff',
	"walk": 'ffffff',
	"walk_block": 'ffffff',
	"change_scene": '0009ff',
	"spawn": 'ffffff',
	"jump": 'ffffff',
	"dialog_config": 'ffffff',
	"sched_event": '0009ff',
	"custom": 'c700ff',
	"camera_set_target": '66b039',
	"camera_set_pos": '66b039',
	"camera_set_zoom_height": '66b039',
	"camera_zoom_in": '66b039',
	"camera_zoom_out": '66b039',
	"autosave": 'ababab',
	"queue_resource": 'acacac',
	"queue_animation": 'acacac',
	"game_over": '00b1ff',
}

func _ready():
	location = get_node('location')
	filen = location.get_node('filen')
	saveb = location.get_node("saveb")
	openb = location.get_node('openb')
	text = get_node('text')
	
	saveb.connect('pressed',self,'find_file',[true])
	openb.connect('pressed',self,'find_file')
	text.connect('text_changed',self,"set_content")
	text.set_text(" ")
	
	filen.connect('text_changed',self,'set_current_file')
	
	#Syntax highlighting
	text.set_syntax_coloring(true)
	text.set_highlight_current_line(true)
	text.set_show_line_numbers(true)  
	text.set_highlight_all_occurrences(true) 
	for item in keywords:
		var tcolor = keywords[item]
		text.add_color_region(item,item,Color(tcolor),true)

func find_file(is_saving = false):
	if is_saving == true:#SAVE
		var file = File.new()
		file.open(current_file, file.WRITE)
		file.store_string(content)
		file.close()
	else:
		var file = File.new()
		file.open(current_file, file.READ)
		content = file.get_as_text()
		text.set_text(content)
		file.close()

#Content
func set_content():
	var string_value = text.get_text()
	content = string_value
func set_current_file():
	var string_value = filen.get_text()
	current_file = string_value

