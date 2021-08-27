# A base class for ESC game scenes
# An extending class can be used in the project settings and is responsible
# for managing very basic game features and controls
tool
extends Node2D
class_name ESCGame


# Editor debug modes
# NONE - No debugging
# MOUSE_TOOLTIP_LIMITS - Visualize the tooltip limits
enum EDITOR_GAME_DEBUG_DISPLAY {
	NONE, 
	MOUSE_TOOLTIP_LIMITS
}


# The safe margin around tooltips
export(float) var mouse_tooltip_margin = 50.0


# A reference to the node handling tooltips
var tooltip_node: Object


# Which (if any) debug mode for the editor is used
export(EDITOR_GAME_DEBUG_DISPLAY) var editor_debug_mode = \
		EDITOR_GAME_DEBUG_DISPLAY.NONE setget _set_editor_debug_mode


# Handle debugging visualizations
func _draw():
	if !Engine.is_editor_hint():
		return
	if editor_debug_mode == EDITOR_GAME_DEBUG_DISPLAY.NONE:
		return
	
	if editor_debug_mode == EDITOR_GAME_DEBUG_DISPLAY.MOUSE_TOOLTIP_LIMITS:
		var mouse_limits: Rect2 = get_viewport_rect().grow(
			-mouse_tooltip_margin
		)
		print(mouse_limits)
		
		# Draw lines for tooltip limits
		draw_rect(mouse_limits, ColorN("red"), false, 10.0)


# Called when the player left clicks on the background
# (Needs to be overridden, if supported)
# 
# #### Parameters
#
# - position: Position clicked
func left_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk",
		[escoria.main.current_scene.player.global_id, position],
		true
	)


# Called when the player right clicks on the background
# (Needs to be overridden, if supported)
# 
# #### Parameters
#
# - position: Position clicked	
func right_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk", 
		[escoria.main.current_scene.player.global_id, position],
		true
	)


# Called when the player double clicks on the background
# (Needs to be overridden, if supported)
# 
# #### Parameters
#
# - position: Position clicked
func left_double_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk", 
		[escoria.main.current_scene.player.global_id, position, true],
		true
	)

# Called when an element in the scene was focused
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - element_id: Global id of the element focused
func element_focused(element_id: String) -> void:
	pass


# Called when no element is focused anymore
# (Needs to be overridden, if supported)
func element_unfocused() -> void:
	pass


# Called when an item was left clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - item_global_id: Global id of the item that was clicked
# - event: The received input event
func left_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do(
		"item_left_click", 
		[item_global_id, event],
		true
	)


# Called when an item was right clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - item_global_id: Global id of the item that was clicked
# - event: The received input event
func right_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do(
		"item_right_click", 
		[item_global_id, event],
		true
	)


# Called when an item was double clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - item_global_id: Global id of the item that was clicked
# - event: The received input event
func left_double_click_on_item(
	item_global_id: String, 
	event: InputEvent
) -> void:
	escoria.do(
		"item_left_click", 
		[item_global_id, event],
		true
	) 


# Called when an inventory item was left clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - inventory_item_global_id: Global id of the inventory item was clicked
# - event: The received input event
func left_click_on_inventory_item(
	inventory_item_global_id: String, 
	event: InputEvent
) -> void:
	pass


# Called when an inventory item was right clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - inventory_item_global_id: Global id of the inventory item was clicked
# - event: The received input event
func right_click_on_inventory_item(
	inventory_item_global_id: String, 
	event: InputEvent
) -> void:
	pass


# Called when an inventory item was double clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - inventory_item_global_id: Global id of the inventory item was clicked
# - event: The received input event
func left_double_click_on_inventory_item(
	inventory_item_global_id: String,
	event: InputEvent
) -> void:
	pass


# Called when an inventory item was focused
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - inventory_item_global_id: Global id of the inventory item that was focused
func inventory_item_focused(inventory_item_global_id: String) -> void:
	pass


# Called when no inventory item is focused anymore
# (Needs to be overridden, if supported)
func inventory_item_unfocused() -> void:
	pass


# Called when the inventory was opened
# (Needs to be overridden, if supported)
func open_inventory():
	pass


# Called when the inventory was closed
# (Needs to be overridden, if supported)
func close_inventory():
	pass
	

# Called when the mousewheel was used
# (Needs to be overridden, if supported)
#
# #### Parameter
#
# - direction: The direction in which the mouse wheel was rotated
func mousewheel_action(direction: int):
	pass


# Called when the UI should be hidden
# (Needs to be overridden, if supported)
func hide_ui():
	pass
	

# Called when the UI should be shown
# (Needs to be overridden, if supported)
func show_ui():
	pass


# Function is called if Project setting escoria/ui/tooltip_follows_mouse = true
#
# #### Parameters
#
# - p_position: Position of the mouse
func update_tooltip_following_mouse_position(p_position: Vector2):
	var corrected_position = p_position
	
	# clamp TOP
	if tooltip_node.tooltip_distance_to_edge_top(p_position) <= mouse_tooltip_margin:
		corrected_position.y = mouse_tooltip_margin
	
	# clamp BOTTOM
	if tooltip_node.tooltip_distance_to_edge_bottom(p_position + tooltip_node.rect_size) <= mouse_tooltip_margin:
		corrected_position.y = escoria.game_size.y - mouse_tooltip_margin - tooltip_node.rect_size.y
	
	# clamp LEFT
	if tooltip_node.tooltip_distance_to_edge_left(p_position - tooltip_node.rect_size/2) <= mouse_tooltip_margin:
		corrected_position.x = mouse_tooltip_margin

	# clamp RIGHT
	if tooltip_node.tooltip_distance_to_edge_right(p_position + tooltip_node.rect_size/2) <= mouse_tooltip_margin:
		corrected_position.x = escoria.game_size.x - mouse_tooltip_margin - tooltip_node.rect_size.x
	
	tooltip_node.anchor_right = 0.2
	tooltip_node.rect_position = corrected_position + tooltip_node.offset_from_cursor


# Set the Editor debug mode
func _set_editor_debug_mode(p_editor_debug_mode: int) -> void:
	editor_debug_mode = p_editor_debug_mode
	update()
