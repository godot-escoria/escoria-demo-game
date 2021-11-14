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
class_name ESCBackground, "res://addons/escoria-core/design/esc_background.svg"


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

# Emitted when the mouse wheel was turned up
signal mouse_wheel_up

# Emitted when the mouse wheel was turned down
signal mouse_wheel_down


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
	
	add_child(area)

# Disable mouse filter events and connect our own events to the ESC input
# manager
func _ready():
	mouse_filter = MOUSE_FILTER_IGNORE
	
	if !Engine.is_editor_hint():
		escoria.inputs_manager.register_background(self)


# Manage inputs reaching the Area2D and emit the events to the input manager
#
# #### Parameters
# - event: Event received
func _unhandled_input(event) -> void:
	if not escoria.current_state == escoria.GAME_STATE.DEFAULT:
		return
	if InputMap.has_action("switch_action_verb") \
			and event.is_action_pressed("switch_action_verb"):
		if event.button_index == BUTTON_WHEEL_UP:
			emit_signal("mouse_wheel_up")
		elif event.button_index == BUTTON_WHEEL_DOWN:
			emit_signal("mouse_wheel_down")
	if event is InputEventMouseButton and event.is_pressed():
		var p = get_global_mouse_position()
		var size
		if get_texture():
			size = get_texture().get_size()
		else:
			size = rect_size
		if Rect2(rect_position, size).has_point(p):
			if event.doubleclick and event.button_index == BUTTON_LEFT:
				emit_signal("double_left_click_on_bg", p)
			elif event.button_index == BUTTON_LEFT:
				emit_signal("left_click_on_bg", p)
			elif event.button_index == BUTTON_RIGHT:
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
