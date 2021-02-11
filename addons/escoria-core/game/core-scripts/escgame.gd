tool
extends Node2D
class_name ESCGame

func get_class():
	return "ESCGame"


export(float) var mouse_tooltip_margin = 50.0

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


## EVENTS
func _on_event_done(event_name: String):
	pass

func _on_tooltip_position_update_required(p_position : Vector2):
	pass
