extends Sprite

signal left_click_on_bg
signal right_click_on_bg  # Connect this in your game/signal_script

export var action = "walk"
var area

# Godot doesn't do doubleclicks so we must
var last_lmb_dt = 0
var waiting_dblclick = null  # null or [pos, event]

func input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# If we are hovering items, do not allow background to receive a click
		# and let the items sort out who's on top and gets to be `clicked`
		if vm.hover_stack:
			return

		if event.button_index == BUTTON_LEFT:
			last_lmb_dt = 0
			waiting_dblclick = [get_global_mouse_position(), event]
		elif event.button_index == BUTTON_RIGHT:
			emit_signal("right_click_on_bg")

func get_action():
	return action

func _physics_process(dt):
	last_lmb_dt += dt

	if waiting_dblclick and last_lmb_dt > vm.DOUBLECLICK_TIMEOUT:
		print("ok")
		emit_signal("left_click_on_bg", self, waiting_dblclick[0], waiting_dblclick[1])
		last_lmb_dt = 0
		waiting_dblclick = null

func _enter_tree():
	# Use size of background texture to calculate collision shape
	var size = get_texture().get_size()

	area = Area2D.new()
	var shape = RectangleShape2D.new()

	var sid = area.create_shape_owner(area)

	# Move origin of Area2D to center of Sprite
	var transform = area.shape_owner_get_transform(sid)
	transform.origin = size / 2
	area.shape_owner_set_transform(sid, transform)

	# Set extents of RectangleShape2D to cover entire Sprite
	shape.set_extents(size / 2)
	area.shape_owner_add_shape(sid, shape)

	add_child(area)

func _ready():
	area.connect("input_event", self, "input")
	connect("left_click_on_bg", $"../game", "ev_left_click_on_bg")
	add_to_group("background")

