extends "res://globals/interactive.gd"

export(String, FILE, ".esc") var esc_script
export var global_id = ""
export var tooltip = ""

var event_table = {}
var clicked = false

func is_clicked():
	return clicked

func area_input(viewport, event, shape_idx):
	input(event)

func input(event):
	if event is InputEventMouseButton || event.is_action("ui_accept"):
		if event.is_pressed():
			clicked = true
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clicked", self, event.get_global_position(), event)
			_check_focus(true, true)
		else:
			clicked = false

func _ready():
	var area
	if has_node("area"):
		area = get_node("area")
	else:
		area = self
	if area is Area2D:
		area.connect("input_event", self, "area_input")
	else:
		area.connect("gui_input", self, "input")

	area.connect("mouse_entered", self, "mouse_enter")
	area.connect("mouse_exited", self, "mouse_exit")

