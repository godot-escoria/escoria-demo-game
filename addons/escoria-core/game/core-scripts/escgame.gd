tool
extends Node2D
class_name ESCGame

func get_class():
	return "ESCGame"


export(float) var mouse_tooltip_margin = 50.0
var tooltip_node : Object

### EDITOR TOOLS ###
enum EDITOR_GAME_DEBUG_DISPLAY {
	NONE, 
	MOUSE_TOOLTIP_LIMITS
}
export(EDITOR_GAME_DEBUG_DISPLAY) var editor_debug_mode = EDITOR_GAME_DEBUG_DISPLAY.NONE setget set_editor_debug_mode



func set_editor_debug_mode(p_editor_debug_mode : int) -> void:
	editor_debug_mode = p_editor_debug_mode
	update()

func _draw():
	if !Engine.is_editor_hint():
		return
	if editor_debug_mode == EDITOR_GAME_DEBUG_DISPLAY.NONE:
		return
	
	if editor_debug_mode == EDITOR_GAME_DEBUG_DISPLAY.MOUSE_TOOLTIP_LIMITS:
		var mouse_limits : Rect2 = get_viewport_rect().grow(-mouse_tooltip_margin)
		print(mouse_limits)
		
		# Draw lines for tooltip limits
		draw_rect(mouse_limits, ColorN("red"), false, 10.0)
	return


## BACKGROUND ## 
func left_click_on_bg(position : Vector2) -> void:
	pass
	
func right_click_on_bg(position : Vector2) -> void:
	pass
	
func left_double_click_on_bg(position : Vector2) -> void:
	pass

## ITEM/HOTSPOT FOCUS ## 
func element_focused(element_id : String) -> void:
	pass

func element_unfocused() -> void:
	pass


## ITEMS ##
func left_click_on_item(item_global_id : String, event : InputEvent) -> void:
	pass

func right_click_on_item(item_global_id : String, event : InputEvent) -> void:
	pass

func left_double_click_on_item(item_global_id : String, event : InputEvent) -> void:
	pass


## INVENTORY ##
func left_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	pass

func right_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	pass

func left_double_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	pass

func inventory_item_focused(inventory_item_global_id : String) -> void:
	pass
	
func inventory_item_unfocused() -> void:
	pass

func open_inventory():
	pass

func close_inventory():
	pass
	
## MOUSEWHEEL ACTION ##
func mousewheel_action(direction : int):
	pass


## UI SPECIFICS
func hide_ui():
	pass
	
func show_ui():
	pass



## FUNCTIONS BELOW THIS POINT DON'T NEED TO BE REIMPLEMENTED BY USER
## (Although they can be, if required)

# This function is called if Project setting escoria/ui/tooltip_follows_mouse = true
func update_tooltip_following_mouse_position(p_position : Vector2):
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
