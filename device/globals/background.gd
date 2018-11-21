extends Sprite

signal left_click_on_bg
signal right_click_on_bg  # Connect this in your game/rmb_script

export var action = "walk"
var area

func input(viewport, event, shape_idx):
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
				return

	if event is InputEventMouseButton and event.pressed:
		if (event.button_index == BUTTON_LEFT):
			var pos = get_global_mouse_position()
			emit_signal("left_click_on_bg", self, pos, event)
		elif (event.button_index == BUTTON_RIGHT):
			emit_signal("right_click_on_bg")

func get_action():
	return action

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

