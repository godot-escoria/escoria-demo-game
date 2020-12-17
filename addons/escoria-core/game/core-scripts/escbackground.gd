tool
extends TextureRect
class_name ESCBackground

func get_class():
	return "ESCBackground"

signal double_left_click_on_bg(position)
signal left_click_on_bg(position)
signal right_click_on_bg(position)
signal mouse_moved

export(String, FILE, "*.esc") var esc_script = ""

# Actual size of the scene
var size : Vector2

"""
ESCBackground purpose is to display a background image and receive input events
on the background. More precisely, the TextureRect under ESCBackground does not
receive events itself - if it did, it would also eat all events like hotspot
focusing and such. Instead, we set the TextureRect mouse filter to 
MOUSE_FILTER_IGNORE, and we use an Area2D node to receive the input events.

If ESCBackground doesn't contain a texture, it is important that its rect_size 
is set over the whole scene, because its rect_size is then used to create the 
Area2D node under it. If the rect_size is wrongly set, the background may 
receive no input.
"""

# PRIVATE VARS
var area : Area2D
var actual_click_position : Vector2

# Godot doesn't do doubleclicks so we must
var last_lmb_dt = 0
var waiting_dblclick = null  # null or [pos, event]

func _enter_tree():
	# Use size of background texture to calculate collision shape if any
	if get_texture():
		size = get_texture().get_size()
	else:
		size = rect_size

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
	mouse_filter = MOUSE_FILTER_IGNORE
	area.connect("input_event", self, "manage_input")
	connect("gui_input", self, "manage_input_texturerect")

	if !Engine.is_editor_hint():
		connect("left_click_on_bg", escoria.inputs_manager, "_on_left_click_on_bg")
		connect("right_click_on_bg", escoria.inputs_manager, "_on_right_click_on_bg")
		connect("double_left_click_on_bg", escoria.inputs_manager, "_on_double_left_click_on_bg")
#		connect("mouse_moved_on_bg", escoria.inputs_manager, "_on_mouse_moved_on_bg")

func manage_input(_viewport, event, _shape_idx):
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
#	elif event is InputEventMouseMotion:
#		emit_signal("mouse_moved_on_bg")
		
				

func manage_input_texturerect(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_LEFT:
			emit_signal("left_click_on_bg", event.position)
		if event.button_index == BUTTON_RIGHT:
			emit_signal("right_click_on_bg", event.position)
	else:
		pass
