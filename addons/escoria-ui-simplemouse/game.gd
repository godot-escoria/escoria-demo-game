tool
extends ESCGame

"""
Implement methods to react to inputs.

- left_click_on_bg(position: Vector2)
- right_click_on_bg(position: Vector2)
- left_double_click_on_bg(position: Vector2)

- element_focused(element_id: String)
- element_unfocused()

- left_click_on_item(item_global_id: String, event: InputEvent)
- right_click_on_item(item_global_id: String, event: InputEvent)
- left_double_click_on_item(item_global_id: String, event: InputEvent)

- left_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent)
- right_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent)
- left_double_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent)
- inventory_item_focused(inventory_item_global_id: String)
- inventory_item_unfocused()
- open_inventory()
- close_inventory()

- mousewheel_action(direction: int)

- hide_ui()
- show_ui()

- _on_event_done(event_name: String)
"""

func _ready():
	ProjectSettings.set_setting("escoria/ui/tooltip_follows_mouse", true)


## BACKGROUND ## 

func left_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk", 
		[escoria.main.current_scene.player.global_id, position],
		true
	)
	$ui/verbs_layer/verbs_menu.set_by_name("walk")
	$ui/verbs_layer/verbs_menu.clear_tool_texture()
	
func right_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk", 
		[escoria.main.current_scene.player.global_id, position],
		true
	)
	$ui/verbs_layer/verbs_menu.set_by_name("walk")
	$ui/verbs_layer/verbs_menu.clear_tool_texture()
	
func left_double_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk", 
		[escoria.main.current_scene.player.global_id, position, true],
		true
	)
	$ui/verbs_layer/verbs_menu.set_by_name("walk")
	$ui/verbs_layer/verbs_menu.clear_tool_texture()

## ITEM/HOTSPOT FOCUS ## 

func element_focused(element_id: String) -> void:
	var target_obj = escoria.object_manager.get_object(element_id).node
	$ui/tooltip_layer/tooltip.set_target(target_obj.tooltip_name)

	if escoria.action_manager.current_action != "use" \
			and escoria.action_manager.current_tool == null:
		if target_obj is ESCItem:
			$ui/verbs_layer/verbs_menu.set_by_name(target_obj.default_action)

func element_unfocused() -> void:
	$ui/tooltip_layer/tooltip.set_target("")


## ITEMS ##

func left_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event], true)

func right_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_right_click", [item_global_id, event], true)

func left_double_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event], true) 


## INVENTORY ##
func left_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_left_click", [inventory_item_global_id, event])
	if escoria.action_manager.current_action == "use":
		var item = escoria.object_manager.get_object(
			inventory_item_global_id
		).node
		if item.has_method("get_sprite") and item.get_sprite().texture:
			$ui/verbs_layer/verbs_menu.set_tool_texture(
				item.get_sprite().texture
			)
		elif item.inventory_item.texture_normal:
			$ui/verbs_layer/verbs_menu.set_tool_texture(
				item.inventory_item.texture_normal
			)
			

func right_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_right_click", [inventory_item_global_id, event], true)


func left_double_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	pass


func inventory_item_focused(inventory_item_global_id: String) -> void:
	$ui/tooltip_layer/tooltip.set_target(
		escoria.object_manager.get_object(
			inventory_item_global_id
		).node.tooltip_name
	)


func inventory_item_unfocused() -> void:
	$ui/tooltip_layer/tooltip.set_target("")


func open_inventory():
	$ui/inventory_layer/inventory_ui/inventory_button.show_inventory()


func close_inventory():
	$ui/inventory_layer/inventory_ui/inventory_button.close_inventory()


func mousewheel_action(direction: int):
	$ui/verbs_layer/verbs_menu.iterate_actions_cursor(direction)


func hide_ui():
	$ui/inventory_layer/inventory_ui.hide()
	
	
func show_ui():
	$ui/inventory_layer/inventory_ui.show()


func _on_event_done(event_name: String):
	escoria.action_manager.clear_current_action()
	$ui/verbs_layer/verbs_menu.clear_tool_texture()


func pause_game():
	if $ui/pause_menu.visible:
		$ui/pause_menu.hide()
		escoria.main.current_scene.game.get_node("camera").current = true
		escoria.main.current_scene.game.show_ui()
		escoria.main.current_scene.show()
	else:
		$ui/pause_menu.show()
		escoria.main.current_scene.game.get_node("camera").current = false
		escoria.main.current_scene.game.hide_ui()
		escoria.main.current_scene.hide()
