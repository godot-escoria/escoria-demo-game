# ESCBackground's purpose is to display a background image and receive input 
# events on the background. More precisely, the TextureRect under ESCBackground 
# does not receive events itself - if it did, it would also eat all events like 
# hotspot focusing and such. Instead, we set the TextureRect mouse filter to 
# MOUSE_FILTER_IGNORE, and we use an Area2D node to receive the input events.
# 
# If ESCBackground doesn't contain a texture, it is important that its rect_size 
# is set over the whole scene, because its rect_size is then used to create the 
# Area2D node under it. If the rect_size is wrongly set, the background may 
# receive no input.
tool
extends TextureRect
class_name ESCBackground


# The background was double clicked
#
# #### Parameters
#
# - position: The position where the player clicked
signal double_left_click_on_bg(position)

# The background was left clicked
#
# #### Parameters
#
# - position: The position where the player clicked
signal left_click_on_bg(position)

# The background was right clicked
#
# #### Parameters
#
# - position: The position where the player clicked
signal right_click_on_bg(position)


# The ESC script connected to this background
export(String, FILE, "*.esc") var esc_script = ""


# Create the underlying Area2D as an input device
func _enter_tree():
	var size
	if get_texture():
		size = get_texture().get_size()
	else:
		size = rect_size

	var area = Area2D.new()
	var shape = RectangleShape2D.new()

	var sid = area.create_shape_owner(area)

	# Move origin of Area2D to center of Sprite
	var transform = area.shape_owner_get_transform(sid)
	transform.origin = size / 2
	area.shape_owner_set_transform(sid, transform)

	# Set extents of RectangleShape2D to cover entire TextureRect
	shape.set_extents(size / 2)
	area.shape_owner_add_shape(sid, shape)
	
	# Handle inputs to the Area2D ourself
	area.connect("input_event", self, "manage_input")

	add_child(area)

# Disable mouse filter events and connect our own events to the ESC input
# manager
func _ready():
	mouse_filter = MOUSE_FILTER_IGNORE
	
	if !Engine.is_editor_hint():
		connect("left_click_on_bg", escoria.inputs_manager, "_on_left_click_on_bg")
		connect("right_click_on_bg", escoria.inputs_manager, "_on_right_click_on_bg")
		connect("double_left_click_on_bg", escoria.inputs_manager, "_on_double_left_click_on_bg")


# Manage inputs reaching the Area2D and emit the events to the input manager
# TODO: Don't change private variables here, use an event for BUTTON_WHEEL
#
# #### Parameters
# - _viewport: (not used)
# - event: Event received
# - _shape_idx: (not used)
func manage_input(_viewport, event, _shape_idx) -> void:
	if event.is_action_pressed("switch_action_verb"):
		if event.button_index == BUTTON_WHEEL_UP:
			escoria.inputs_manager._on_mousewheel_action(-1)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			escoria.inputs_manager._on_mousewheel_action(1)
	if event is InputEventMouseButton:
		var p = get_global_mouse_position()
		if event.doubleclick:
			if event.button_index == BUTTON_LEFT:
				emit_signal("double_left_click_on_bg", p)
		else:
			if event.is_pressed():
				if event.button_index == BUTTON_LEFT:
					emit_signal("left_click_on_bg", p)
				if event.button_index == BUTTON_RIGHT:
					emit_signal("right_click_on_bg", p)
				

# Calculate the actual area taken by this background depending on its
# Texture or set size
# **Returns** The correct area size
func get_full_area_rect2() -> Rect2:
	var area_rect2: Rect2 = Rect2()
	var pos = get_global_position()
	var size: Vector2
	if get_texture():
		size = get_texture().get_size()
	else:
		size = rect_size
		
	if rect_scale.x != 1 or rect_scale.y != 1:
		size.x *= rect_scale.x
		size.y *= rect_scale.y

	area_rect2 = area_rect2.expand(pos)
	area_rect2 = area_rect2.expand(pos + size)
	return area_rect2
