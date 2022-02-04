extends ESCGame


const VERB_WALK = "walk"


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

- pause_game()
- unpause_game()
- show_main_menu()
- hide_main_menu()

- apply_custom_settings()

- _on_event_done(event_name: String)
"""

func _enter_tree():
	var room_selector_parent = $CanvasLayer/ui/HBoxContainer/VBoxContainer
	
	if ProjectSettings.get_setting("escoria/debug/enable_room_selector") and \
			room_selector_parent.get_node_or_null("room_select") == null:
		room_selector_parent.add_child(
			preload(
				"res://addons/escoria-core/ui_library/tools/room_select" +\
				"/room_select.tscn"
			).instance()
		)

	
func _input(event: InputEvent) -> void:
	if escoria.main.current_scene and escoria.main.current_scene.game:
			if event is InputEventMouseMotion:
				escoria.main.current_scene.game. \
					update_tooltip_following_mouse_position(event.position)


## BACKGROUND ## 

func left_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.action_manager.do(
			escoria.action_manager.ACTION.BACKGROUND_CLICK, 
			[escoria.main.current_scene.player.global_id, position],
			true
		)
		$mouse_layer/verbs_menu.set_by_name(VERB_WALK)
		$mouse_layer/verbs_menu.clear_tool_texture()
	
func right_click_on_bg(position: Vector2) -> void:
	mousewheel_action(1)
	
func left_double_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.action_manager.do(
			escoria.action_manager.ACTION.BACKGROUND_CLICK, 
			[escoria.main.current_scene.player.global_id, position, true],
			true
		)
		$mouse_layer/verbs_menu.set_by_name(VERB_WALK)
		$mouse_layer/verbs_menu.clear_tool_texture()

## ITEM/HOTSPOT FOCUS ## 

func element_focused(element_id: String) -> void:
	var target_obj = escoria.object_manager.get_object(element_id).node
	$tooltip_layer/tooltip.set_target(target_obj.tooltip_name)

	if escoria.action_manager.current_action != "use" \
			and escoria.action_manager.current_tool == null:
		if target_obj is ESCItem:
			$mouse_layer/verbs_menu.set_by_name(
				escoria.action_to_string(target_obj.default_action)
			)

func element_unfocused() -> void:
	$tooltip_layer/tooltip.set_target("")


## ITEMS ##

func left_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_LEFT_CLICK, 
		[item_global_id, event], 
		true
	)

func right_click_on_item(item_global_id: String, event: InputEvent) -> void:
	mousewheel_action(1)

func left_double_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_LEFT_CLICK, 
		[item_global_id, event], 
		true
	) 


## INVENTORY ##
func left_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_LEFT_CLICK, 
		[inventory_item_global_id, event]
	)
	
	if escoria.action_manager.current_action == "use":
		var item = escoria.object_manager.get_object(
			inventory_item_global_id
		).node
		if item.has_method("get_sprite") and item.get_sprite().texture:
			$mouse_layer/verbs_menu.set_tool_texture(
				item.get_sprite().texture
			)
		elif item.inventory_item.texture_normal:
			$mouse_layer/verbs_menu.set_tool_texture(
				item.inventory_item.texture_normal
			)
			

func right_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	mousewheel_action(1)


func left_double_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	pass


func inventory_item_focused(inventory_item_global_id: String) -> void:
	$tooltip_layer/tooltip.set_target(
		escoria.object_manager.get_object(
			inventory_item_global_id
		).node.tooltip_name
	)


func inventory_item_unfocused() -> void:
	$tooltip_layer/tooltip.set_target("")


func open_inventory():
	$CanvasLayer/ui/HBoxContainer/inventory_ui.show_inventory()


func close_inventory():
	$CanvasLayer/ui/HBoxContainer/inventory_ui.hide_inventory()


func mousewheel_action(direction: int):
	$mouse_layer/verbs_menu.iterate_actions_cursor(direction)


func hide_ui():
	$CanvasLayer/ui/HBoxContainer/inventory_ui.hide()
	
	
func show_ui():
	$CanvasLayer/ui/HBoxContainer/inventory_ui.show()

func hide_main_menu():
	if get_node(main_menu).visible:
		get_node(main_menu).hide()

func show_main_menu():
	if not get_node(main_menu).visible:
		get_node(main_menu).reset()
		get_node(main_menu).show()

func unpause_game():
	if get_node(pause_menu).visible:
		get_node(pause_menu).hide()
		escoria.object_manager.get_object("_camera").node.current = true
		escoria.main.current_scene.game.show_ui()
		escoria.main.current_scene.show()

func pause_game():
	if not get_node(pause_menu).visible:
		get_node(main_menu).reset()
		get_node(pause_menu).set_save_enabled(
			escoria.save_manager.save_enabled
		)
		get_node(pause_menu).show()
		escoria.object_manager.get_object("_camera").node.current = false
		escoria.main.current_scene.game.hide_ui()
		escoria.main.current_scene.hide()


func apply_custom_settings(custom_settings: Dictionary):
	if custom_settings.has("a_custom_setting"):
		escoria.logger.info(
			"custom setting value loaded:", 
			[custom_settings["a_custom_setting"]]
		)


func get_custom_data() -> Dictionary:
	return {
		"ui_type": "simplemouse"
	}
	

# Update the tooltip
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


func _on_action_finished():
	$mouse_layer/verbs_menu.clear_tool_texture()
	$mouse_layer/verbs_menu.iterate_actions_cursor(0)

func _on_event_done(_return_code: int, _event_name: String):
	escoria.action_manager.clear_current_action()
	$mouse_layer/verbs_menu.clear_tool_texture()


func _on_MenuButton_pressed() -> void:
	pause_game()
