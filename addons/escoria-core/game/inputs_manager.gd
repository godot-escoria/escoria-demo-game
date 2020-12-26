tool
extends Node

var is_hotspot_focused : bool

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("esc_show_debug_prompt"):
		escoria.main.get_node("layers/debug_layer/esc_prompt_popup").popup()

###################################################################################

func _on_left_click_on_bg(position : Vector2):
	if !is_hotspot_focused:
		printt("Left click on background at ", str(position))
		escoria.main.current_scene.game.left_click_on_bg(position)


func _on_double_left_click_on_bg(position : Vector2):
	if !is_hotspot_focused:
		printt("Double left click on background at ", str(position))
		escoria.main.current_scene.game.left_double_click_on_bg(position)


func _on_right_click_on_bg(position : Vector2):
	if !is_hotspot_focused:
		printt("Right click on background at ", str(position))
		escoria.main.current_scene.game.right_click_on_bg(position)

##################################################################################

func _on_mouse_entered_hotspot(hotspot_global_id : String) -> void:
	printt("Hotspot focused : ", hotspot_global_id)
	is_hotspot_focused = true
	escoria.main.current_scene.game.element_focused(hotspot_global_id)

func _on_mouse_exited_hotspot() -> void:
	print("Hotspot unfocused")
	is_hotspot_focused = false
	escoria.main.current_scene.game.element_unfocused()

func _on_mouse_left_clicked_hotspot(hotspot_global_id : String, event : InputEvent) -> void:
	printt("Hotspot left clicked", hotspot_global_id, event)
	escoria.main.current_scene.game.left_click_on_hotspot(hotspot_global_id, event)

func _on_mouse_right_clicked_hotspot(hotspot_global_id : String, event : InputEvent) -> void:
	printt("Hotspot right clicked", hotspot_global_id, event)
	escoria.main.current_scene.game.right_click_on_hotspot(hotspot_global_id, event)

func _on_mouse_left_double_clicked_hotspot(hotspot_global_id : String, event : InputEvent) -> void:
	printt("Hotspot right clicked", hotspot_global_id, event)
	escoria.main.current_scene.game.left_double_click_on_hotspot(hotspot_global_id, event)

##################################################################################

func _on_mouse_left_click_inventory_item(inventory_item_global_id, event : InputEvent) -> void:
	printt("Inventory item left clicked ", inventory_item_global_id)
	escoria.main.current_scene.game.left_click_on_inventory_item(inventory_item_global_id, event)

func _on_mouse_right_click_inventory_item(inventory_item_global_id, event : InputEvent) -> void:
	printt("Inventory item right clicked ", inventory_item_global_id)
	escoria.main.current_scene.game.right_click_on_inventory_item(inventory_item_global_id, event)

func _on_mouse_double_left_click_inventory_item(inventory_item_global_id, event : InputEvent) -> void:
	printt("Inventory item double left clicked ", inventory_item_global_id)
	escoria.main.current_scene.game.left_double_click_on_inventory_item(inventory_item_global_id, event)

func _on_mouse_entered_inventory_item(inventory_item_global_id) -> void:
	printt("Inventory item focused ", inventory_item_global_id)
	escoria.main.current_scene.game.inventory_item_focused(inventory_item_global_id)

func _on_mouse_exited_inventory_item() -> void:
	printt("Inventory item unfocused")
	escoria.main.current_scene.game.inventory_item_unfocused()


##################################################################################

func _on_mouse_entered_item(item_global_id : String) -> void:
	printt("Item focused : ", item_global_id)
	is_hotspot_focused = true
	escoria.main.current_scene.game.element_focused(item_global_id)

func _on_mouse_exited_item() -> void:
	print("Item unfocused")
	is_hotspot_focused = false
	escoria.main.current_scene.game.element_unfocused()
	
func _on_mouse_left_clicked_item(item_global_id : String, event : InputEvent) -> void:
	printt("Item left clicked", item_global_id, event)
	escoria.main.current_scene.game.left_click_on_item(item_global_id, event)

func _on_mouse_left_double_clicked_item(item_global_id : String, event : InputEvent) -> void:
	printt("Item left double clicked", item_global_id, event)
	escoria.main.current_scene.game.left_double_click_on_item(item_global_id, event)

func _on_mouse_right_clicked_item(item_global_id : String, event : InputEvent) -> void:
	printt("Item right clicked", item_global_id, event)
	escoria.main.current_scene.game.right_click_on_item(item_global_id, event)
