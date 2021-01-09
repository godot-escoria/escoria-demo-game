extends Node

"""
Implement methods to react to inputs.

- left_click_on_bg(position : Vector2)
- right_click_on_bg(position : Vector2)
- left_double_click_on_bg(position : Vector2)

- element_focused(element_id : String)
- element_unfocused()

- left_click_on_hotspot(hotspot_global_id : String, event : InputEvent)
- right_click_on_hotspot(hotspot_global_id : String, event : InputEvent)
- left_double_click_on_hotspot(hotspot_global_id : String, event : InputEvent)

- left_click_on_item(item_global_id : String, event : InputEvent)
- right_click_on_item(item_global_id : String, event : InputEvent)
- left_double_click_on_item(item_global_id : String, event : InputEvent)
"""

signal element_focused(element_global_id)


#func _input(event):
#	if event.is_action_pressed("switch_action_verb"):
#		if event.button_index == BUTTON_WHEEL_UP:
#			$ui/verbs_layer/verbs_menu.iterate_actions_cursor(-1)
#		elif event.button_index == BUTTON_WHEEL_DOWN:
#			$ui/verbs_layer/verbs_menu.iterate_actions_cursor(1)

## BACKGROUND ## 

func left_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position])
	
func right_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position])
	
func left_double_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position, true])


## ITEM/HOTSPOT FOCUS ## 

func element_focused(element_id : String) -> void:
	#emit_signal("element_focused", element_id)
	var target_obj = escoria.esc_runner.get_object(element_id)
	if escoria.esc_runner.current_action != "use" && escoria.esc_runner.current_tool == null:
		if target_obj is ESCItem or target_obj is ESCHotspot:
			$ui/verbs_layer/verbs_menu.set_by_name(target_obj.default_action)

func element_unfocused() -> void:
	#emit_signal("element_focused", "")
	#$ui/verbs_layer/verbs_menu.set_by_name("walk")
	pass


## HOTSPOTS ##

func left_click_on_hotspot(hotspot_global_id : String, event : InputEvent) -> void:
	escoria.do("hotspot_left_click", [hotspot_global_id, event])

func right_click_on_hotspot(hotspot_global_id : String, event : InputEvent) -> void:
	escoria.do("hotspot_right_click", [hotspot_global_id, event])

func left_double_click_on_hotspot(hotspot_global_id : String, event : InputEvent) -> void:
	escoria.do("hotspot_left_click", [hotspot_global_id, event])


## ITEMS ##

func left_click_on_item(item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event])

func right_click_on_item(item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_right_click", [item_global_id, event])

func left_double_click_on_item(item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event]) 


## INVENTORY ##
func left_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_left_click", [inventory_item_global_id, event])
	if escoria.esc_runner.current_action == "use":
		var item = escoria.esc_runner.get_object(inventory_item_global_id)
		if item.texture:
			$ui/verbs_layer/verbs_menu.set_tool_texture(item.texture)
		elif item.inventory_item_scene_file.instance().texture_normal:
			$ui/verbs_layer/verbs_menu.set_tool_texture(item.inventory_item_scene_file.instance().texture_normal)
			

func right_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_right_click", [inventory_item_global_id, event])

func left_double_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	pass

func inventory_item_focused(inventory_item_global_id : String) -> void:
	emit_signal("element_focused", inventory_item_global_id)

func inventory_item_unfocused() -> void:
	emit_signal("element_focused", "")


func open_inventory():
	$ui/inventory_layer/inventory_ui/inventory_button.show_inventory()


func close_inventory():
	$ui/inventory_layer/inventory_ui/inventory_button.close_inventory()

func mousewheel_action(direction : int):
	$ui/verbs_layer/verbs_menu.iterate_actions_cursor(direction)
