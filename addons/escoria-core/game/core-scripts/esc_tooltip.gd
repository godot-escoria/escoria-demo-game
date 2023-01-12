# A tooltip displaying <verb> <item1> [<item2>]
tool
extends RichTextLabel
class_name ESCTooltip


# Maximum width of the label
const MAX_WIDTH = 200

# Minimum height of the label
const MIN_HEIGHT = 30

# Maximum height of the label
const MAX_HEIGHT = 500

# Height of one line in the label
const ONE_LINE_HEIGHT = 16


# Color of the label
export(Color) var color setget set_color

# Vector2 defining the offset from the cursor
export(Vector2) var offset_from_cursor = Vector2(10,0)

# Activates debug mode. If enabled, shows the label with a white background.
export(bool) var debug_mode = false setget set_debug_mode


# Infinitive verb
var current_action: String

# Target item/hotspot
var current_target: String setget set_target

# Preposition: on, with...
var current_prep: String = "with"

# Target 2 item/hotspot
var current_target2: String

# True if tooltip is waiting for a click on second target (use x with y)
var waiting_for_target2 = false

# Node containing the debug white background
var debug_texturerect_node: TextureRect

# Indicates whether the current room is loaded and ready
var _room_is_ready: bool = false


# Connect relevant functions
func _ready():
	escoria.main.connect("room_ready", self, "_on_room_ready")
	escoria.action_manager.connect("action_changed", self, "_on_action_selected")


# Set the color of the label
#
# ## Parameters
# - p_color: the color to set the label
func set_color(p_color: Color):
	color = p_color
	if _room_is_ready:
		update_tooltip_text()


# Enable/disable debug mode of the label. If enabled, the label is displayed
# with a white background.
#
# ## Parameters
# - p_debug_mode: if true, enable debug mode. False to disable
func set_debug_mode(p_debug_mode: bool):
	debug_mode = p_debug_mode
	if debug_mode:
		# Add a white TextureRect behind the RTL to see its actual size
		debug_texturerect_node = TextureRect.new()
		add_child(debug_texturerect_node)
		debug_texturerect_node.texture = load("res://addons/escoria-core/game/assets/images/white.png")
		debug_texturerect_node.expand = true
		debug_texturerect_node.stretch_mode = TextureRect.STRETCH_TILE
		debug_texturerect_node.size_flags_horizontal = SIZE_EXPAND_FILL
		debug_texturerect_node.size_flags_vertical = SIZE_EXPAND_FILL
		debug_texturerect_node.show_behind_parent = true
		debug_texturerect_node.anchor_right = 1.0
		debug_texturerect_node.anchor_bottom = 1.0
		debug_texturerect_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		move_child(debug_texturerect_node, 2)
	else:
		if debug_texturerect_node:
			remove_child(debug_texturerect_node)
			debug_texturerect_node.queue_free()


# Set the first target of the label.
#
# ## Parameters
# - target: String the target to add to the label
# - needs_second_target: if true, the label will prepare for a second target
func set_target(target: String, needs_second_target: bool = false) -> void:
	current_target = target
	waiting_for_target2 = needs_second_target
	if _room_is_ready:
		update_tooltip_text()


# Set the second target of the label
#
# ## Parameters
# - target2: String the second target to add to the label
func set_target2(target2: String) -> void:
	current_target2 = target2
	if _room_is_ready:
		update_tooltip_text()


# Update the tooltip text.
func update_tooltip_text():
	"""
	Overriden method. Should not be called directly.
	"""
	pass


# Update the tooltip size according to the text.
func update_size():
	if not get_tree():
		# We're not in the tree anymore. Return
		return
	rect_size = get_font("normal_font").get_string_size(current_target)


# Calculate the offset of the label depending on its position.
#
# ## Parameters
# - position: the position to test
#
# **Return**
# The calculated offset
func _offset(position: Vector2) -> Vector2:
	var center_offset_x = rect_size.x / 2
	var offset_y = 5

	position.x -= center_offset_x
	position.y += offset_y

	return position


# Return the tooltip distance to top edge.
#
# ## Parameters
# - position: the position to test
#
# **Return**
# The distance to the edge.
func tooltip_distance_to_edge_top(position: Vector2):
	return position.y


# Return the tooltip distance to bottom edge.
#
# ## Parameters
# - position: the position to test
#
# **Return**
# The distance to the edge.
func tooltip_distance_to_edge_bottom(position: Vector2):
	return escoria.game_size.y - position.y


# Return the tooltip distance to left edge.
#
# ## Parameters
# - position: the position to test
#
# **Return**
# The distance to the edge.
func tooltip_distance_to_edge_left(position: Vector2):
	return position.x


# Return the tooltip distance to right edge.
#
# ## Parameters
# - position: the position to test
#
# **Return**
# The distance to the edge.
func tooltip_distance_to_edge_right(position: Vector2):
	return escoria.game_size.x - position.x


# Clear the tooltip targets texts
func clear():
	waiting_for_target2 = false
	set_target("")
	set_target2("")


# Called when the room is loaded to setup the label.
func _on_room_ready():
	escoria.main.current_scene.game.tooltip_node = self
	_room_is_ready = true


# Called when an action is selected in Escoria
func _on_action_selected() -> void:
	current_action = escoria.action_manager.current_action

	if _room_is_ready:
		update_tooltip_text()
