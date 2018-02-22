extends Area2D

export var action = "walk"
var collisionshape_click
var rectangleshape

func input(viewport, event, shape_idx):
	if event.type == InputEvent.MOUSE_BUTTON && event.pressed:
		if (event.button_index == BUTTON_LEFT):
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clicked", self, get_position() + event.position, event)
		elif (event.button_index == BUTTON_RIGHT):
			emit_right_click()

func get_action():
	return action

func _init():
	add_user_signal("right_click_on_bg")

func _enter_tree():
	# Use size of background texture to calculate collision shape
	var background = get_parent().get_node("background")
	if background:
		var size = background.get_size()
		var extents = Vector2(size.x / 2, size.y / 2)
		var transform = Transform2D(Vector2(1, 0), Vector2(0, 1), extents)

		var shape = RectangleShape2D.new()
		shape.set_extents(extents)
		add_shape(shape)
		set_shape_transform(0, transform)

func _ready():
	connect("gui_input", self, "input")
	add_to_group("background")

func emit_right_click():
	emit_signal("right_click_on_bg")
