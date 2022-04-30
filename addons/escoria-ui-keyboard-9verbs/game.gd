extends ESCGame


const VERB_CLOSE = "close"
const VERB_GIVE = "give"
const VERB_LOOK = "look"
const VERB_OPEN = "open"
const VERB_PICKUP = "pickup"
const VERB_PULL = "pull"
const VERB_PUSH = "push"
const VERB_TALK = "talk"
const VERB_USE = "use"


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


onready var verbs_menu = $ui/Control/panel_down/VBoxContainer/HBoxContainer\
		/VerbsMargin/verbs_menu
onready var tooltip = $ui/Control/panel_down/VBoxContainer/MarginContainer\
		/tooltip
onready var room_select = $ui/Control/panel_down/VBoxContainer/HBoxContainer\
		/MainMargin/VBoxContainer/room_select
onready var inventory_ui = $ui/Control/panel_down/VBoxContainer/HBoxContainer\
		/InventoryMargin/inventory_ui
const input_map = preload("res://addons/escoria-ui-keyboard-9verbs/input_map.gd")

func _enter_tree():
	var room_selector_parent = $ui/Control/panel_down/VBoxContainer\
			/HBoxContainer/MainMargin/VBoxContainer

	if ProjectSettings.get_setting("escoria/debug/enable_room_selector") and \
			room_selector_parent.get_node_or_null("room_select") == null:
		room_selector_parent.add_child(
			preload(
				"res://addons/escoria-core/ui_library/tools/room_select" +\
				"/room_select.tscn"
			).instance()
		)

	var input_handler = funcref(self, "_process_input")
	escoria.inputs_manager.register_custom_input_handler(input_handler)
	input_map.add_actions_to_input_map()


func _exit_tree():
	escoria.inputs_manager.register_custom_input_handler(null)
	input_map.erase_actions_from_input_map()


func _process_input(event: InputEvent, is_default_state: bool) -> bool:
	if not is_default_state:
		return false
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_OPEN):
		verbs_menu.on_action_selected(VERB_OPEN)
		return true
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_PICKUP):
		verbs_menu.on_action_selected(VERB_PICKUP)
		return true
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_PUSH):
		verbs_menu.on_action_selected(VERB_PUSH)
		return true
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_CLOSE):
		verbs_menu.on_action_selected(VERB_CLOSE)
		return true
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_LOOK):
		verbs_menu.on_action_selected(VERB_LOOK)
		return true
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_PULL):
		verbs_menu.on_action_selected(VERB_PULL)
		return true
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_GIVE):
		verbs_menu.on_action_selected(VERB_GIVE)
		return true
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_USE):
		verbs_menu.on_action_selected(VERB_USE)
		return true
	elif event.is_action_pressed(input_map.ACTION_SET_VERB_TALK):
		verbs_menu.on_action_selected(VERB_TALK)
		return true
	else:
		return false


## BACKGROUND ##

func left_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.action_manager.do(
			escoria.action_manager.ACTION.BACKGROUND_CLICK,
			[escoria.main.current_scene.player.global_id, position],
			true
		)
		escoria.action_manager.clear_current_action()
		escoria.action_manager.clear_current_tool()
		tooltip.clear()
		verbs_menu.unselect_actions()


func right_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.action_manager.do(
			escoria.action_manager.ACTION.BACKGROUND_CLICK,
			[escoria.main.current_scene.player.global_id, position],
			true
		)
		escoria.action_manager.clear_current_action()
		escoria.action_manager.clear_current_tool()
		tooltip.clear()
		verbs_menu.unselect_actions()


func left_double_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.action_manager.do(
			escoria.action_manager.ACTION.BACKGROUND_CLICK,
			[escoria.main.current_scene.player.global_id, position, true],
			true
		)
		escoria.action_manager.clear_current_action()
		verbs_menu.unselect_actions()


## ITEM FOCUS ##

func element_focused(element_id: String) -> void:
	var target_obj = escoria.object_manager.get_object(element_id).node

	match escoria.action_manager.action_state:
		# Don't change the tooltip if an action input is completed
		# (ie verb+item(+target)) because the action is now being executed
		# and the tooltip is already set because the item was focused
		# (see element_focused() and inventory_item_focused())
		ESCActionManager.ACTION_INPUT_STATE.COMPLETED:
			return

		ESCActionManager.ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM, \
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_ITEM:
			tooltip.set_target(target_obj.tooltip_name)

		ESCActionManager.ACTION_INPUT_STATE.AWAITING_TARGET_ITEM:
			tooltip.set_target2(target_obj.tooltip_name)


func element_unfocused() -> void:
	match escoria.action_manager.action_state:
		# Don't change the tooltip if an action input is completed
		# (ie verb+item(+target)) because the action is now being executed
		# and the tooltip is already set because the item was focused
		# (see element_focused() and inventory_item_focused())
		ESCActionManager.ACTION_INPUT_STATE.COMPLETED:
			return

		ESCActionManager.ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM, \
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_ITEM:
			tooltip.set_target("")
			verbs_menu.unselect_actions()

		ESCActionManager.ACTION_INPUT_STATE.AWAITING_TARGET_ITEM:
			tooltip.set_target2("")



## ITEMS ##
func left_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_LEFT_CLICK,
		[item_global_id, event],
		true
	)

	var target_obj = escoria.object_manager.get_object(
		item_global_id
	).node

	match escoria.action_manager.action_state:
		# Don't change the tooltip if an action input is completed
		# (ie verb+item(+target)) because the action is now being executed
		# and the tooltip is already set because the item was focused
		# (see element_focused() and inventory_item_focused())
		ESCActionManager.ACTION_INPUT_STATE.COMPLETED:
			return

		# Just clicked on the item
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM, \
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_ITEM:
			tooltip.set_target(target_obj.tooltip_name)

		# Clicked on item and now we're awaiting a target item
		# This means we clicked the tool and we now need a target
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_TARGET_ITEM:
			tooltip.set_target(target_obj.tooltip_name, true)



func right_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.set_current_action(verbs_menu.selected_action)
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_RIGHT_CLICK,
		[item_global_id, event],
		true
	)


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

	var target_obj = escoria.object_manager.get_object(
		inventory_item_global_id
	).node

	match escoria.action_manager.action_state:
		# Don't change the tooltip if an action input is completed
		# (ie verb+item(+target)) because the action is now being executed
		# and the tooltip is already set because the item was focused
		# (see element_focused() and inventory_item_focused())
		ESCActionManager.ACTION_INPUT_STATE.COMPLETED:
			return

		# Just clicked on the inventory item: do nothing special
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM, \
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_ITEM:
			return

		# Clicked on inventory item and now we're awaiting a target item
		# This means we clicked the tool and we now need a target
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_TARGET_ITEM:
			tooltip.set_target(target_obj.tooltip_name, true)


func right_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.set_current_action(verbs_menu.selected_action)
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_RIGHT_CLICK,
		[inventory_item_global_id, event]
	)


func left_double_click_on_inventory_item(_inventory_item_global_id: String, _event: InputEvent) -> void:
	pass


func inventory_item_focused(inventory_item_global_id: String) -> void:
	var target_obj = escoria.object_manager.get_object(
			inventory_item_global_id
		).node

	match escoria.action_manager.action_state:
		# Don't change the tooltip if an action input is completed
		# (ie verb+item(+target)) because the action is now being executed
		# and the tooltip is already set because the item was focused
		# (see element_focused() and inventory_item_focused())
		ESCActionManager.ACTION_INPUT_STATE.COMPLETED:
			return

		ESCActionManager.ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM, \
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_ITEM:
			tooltip.set_target(target_obj.tooltip_name)

			# Hovering an ESCItem highlights its default action
			if escoria.action_manager.current_action != VERB_USE and target_obj is ESCItem:
				verbs_menu.set_by_name(target_obj.default_action)

		ESCActionManager.ACTION_INPUT_STATE.AWAITING_TARGET_ITEM:
			tooltip.set_target2(target_obj.tooltip_name)


func inventory_item_unfocused() -> void:

	match escoria.action_manager.action_state:
		ESCActionManager.ACTION_INPUT_STATE.COMPLETED:
			# Don't change the tooltip if an action input is completed
			# (ie verb+item(+target)) because the action is now being executed
			return

		ESCActionManager.ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM, \
		ESCActionManager.ACTION_INPUT_STATE.AWAITING_ITEM:
			tooltip.set_target("")
			verbs_menu.unselect_actions()

		ESCActionManager.ACTION_INPUT_STATE.AWAITING_TARGET_ITEM:
			tooltip.set_target2("")


func open_inventory():
	pass


func close_inventory():
	pass


func mousewheel_action(_direction: int):
	pass


func hide_ui():
	$ui/Control.hide()
	verbs_menu.hide()
	if ProjectSettings.get("escoria/debug/enable_room_selector") == true:
		room_select.hide()
	inventory_ui.hide()
	tooltip.hide()


func show_ui():
	$ui/Control.show()
	verbs_menu.show()
	if ProjectSettings.get("escoria/debug/enable_room_selector") == true:
		room_select.show()
	inventory_ui.show()
	tooltip.show()

func hide_main_menu():
	if get_node(main_menu).visible:
		get_node(main_menu).hide()
		show_ui()

func show_main_menu():
	if not get_node(main_menu).visible:
		hide_ui()
		get_node(main_menu).reset()
		get_node(main_menu).show()

func unpause_game():
	if get_node(pause_menu).visible:
		get_node(pause_menu).hide()
		escoria.object_manager.get_object(escoria.object_manager.CAMERA).node.current = true
		escoria.object_manager.get_object(escoria.object_manager.SPEECH).node.resume()
		escoria.main.current_scene.game.show_ui()
		escoria.main.current_scene.show()
		escoria.set_game_paused(false)

func pause_game():
	if not get_node(pause_menu).visible:
		get_node(pause_menu).reset()
		get_node(pause_menu).set_save_enabled(escoria.save_manager.save_enabled)
		get_node(pause_menu).show()
		escoria.object_manager.get_object(escoria.object_manager.CAMERA).node.current = false
		escoria.object_manager.get_object(escoria.object_manager.SPEECH).node.pause()
		escoria.main.current_scene.game.hide_ui()
		escoria.main.current_scene.hide()
		escoria.set_game_paused(true)


func _on_MenuButton_pressed() -> void:
	pause_game()


func _on_action_finished() -> void:
	verbs_menu.unselect_actions()
	tooltip.clear()

func _on_event_done(_return_code: int, _event_name: String):
	escoria.action_manager.clear_current_action()
	verbs_menu.unselect_actions()
