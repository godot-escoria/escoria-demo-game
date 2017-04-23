# Credits system adapted from Tiny Chopper Raceway 
# by Josh "Cheeseness" Bush
#
# github.com/Cheeseness/tiny-chopper-raceway

extends Control

var vm
var root

func close():
	root.menu_close(self)
	queue_free()

func input(event):
	if event.is_pressed() && !event.is_echo() && event.is_action("menu_request"):
		if root.get_current_scene() extends preload("res://globals/scene.gd"):
			close()

func menu_collapsed():
	close()

func _ready():
	get_node("GoBack").connect("pressed", self, "close")

	var file = File.new()
	file.open("res://credits/credits.txt", File.READ)
	while(!file.eof_reached()):
		get_node("RichTextLabel").add_text(file.get_line())
		get_node("RichTextLabel").newline()

	vm = get_tree().get_root().get_node("vm")
	set_process_input(true)

	root = get_node("/root/main")
	root.menu_open(self)
