extends Sprite

signal left_click_on_bg
signal right_click_on_bg  # Connect this in your game/signal_script

export var action = "walk"
var area

# Godot doesn't do doubleclicks so we must
var last_lmb_dt = 0
var waiting_dblclick = null  # null or [pos, event]

func item_was_clicked():
	## Try the overlay handling here for topmost item
	# If a background is covered by an item, the item "wins"
	var overlay = get_child(0)
	# Eg. Polygon2D does not have this method
	if overlay.has_method("get_overlapping_areas"):
		for area in overlay.get_overlapping_areas():
			if not area is esc_type.ITEM:
				if area.get_parent() is esc_type.ITEM:
					area = area.get_parent()

			# An item won
			if area.has_method("is_clicked") and area.is_clicked():
				return true

	return false

func input(viewport, event, shape_idx):
	if item_was_clicked():
		return

	if event is InputEventMouseButton and event.pressed:
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
	connect("left_click_on_bg", $"/root/scene/game", "ev_left_click_on_bg")
	add_to_group("background")

