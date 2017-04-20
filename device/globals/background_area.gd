extends Area2D

export var action = "walk"
var collisionshape_click
var rectangleshape

func input(viewport, event, shape_idx):
	if event.type == InputEvent.MOUSE_BUTTON && event.pressed:
		if (event.button_index == 1):
			get_tree().call_group(0, "game", "clicked", self, get_pos() + Vector2(event.x, event.y))
		elif (event.button_index == 2):
			emit_right_click()
	
		
func get_action():
	return action

func _init():
	add_user_signal("right_click_on_bg")

func _ready():
	connect("input_event", self, "input")
	add_to_group("background")

	
	

func emit_right_click():
	emit_signal("right_click_on_bg")
