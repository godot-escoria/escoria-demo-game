extends ESCGame


const VERB_USE = "use"
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

# Value to use for `device` argument to various `Input.get_joy` methods.
const JOY_DEVICE = 0

# See https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html?#dead-zone
const DEADZONE = 0.2

# Multiplier to apply to axis when it exceeds DEADZONE.
const AXIS_WEIGHT = 50.0

# JOY_BUTTON_X corresponds to the "X" button on an XBox controller
# or the Square button on a Playstation controller. These appear to
# map to the "primary action," in practice, so we treat it like a left click.
const PRIMARY_ACTION_BUTTON = JOY_BUTTON_X

# JOY_BUTTON_Y corresponds to the "Y" button on an XBox controller
# or the Triangle button on a Playstation controller. These appear to
# map to the "secondary action," in practice, so we treat it like a right click.
const CHANGE_VERB_BUTTON = JOY_BUTTON_Y

# Input action for use by InputMap
const ESC_UI_CHANGE_VERB_ACTION = "esc_change_verb"

# true when a gamepad is connected.
var _is_gamepad_connected = false

# Tracks the mouse's current position onscreen.
var _current_mouse_pos: Vector2 = Vector2.ZERO

var targeted_node: Node


func _ready():
	hide_ui()
	$ui/tooltip.connect("tooltip_size_updated", Callable(self, "update_tooltip_following_mouse_position"))


func _enter_tree():
	initialize_esc_game()

	var room_selector_parent = $ui/HBoxContainer/VBoxContainer

	if ESCProjectSettingsManager.get_setting(ESCProjectSettingsManager.ENABLE_ROOM_SELECTOR) \
		and room_selector_parent.get_node_or_null("room_select") == null:

		room_selector_parent.add_child(
			preload(
				"res://addons/escoria-core/ui_library/tools/room_select" +\
				"/room_select.tscn"
			).instantiate()
		)

	var input_handler = Callable(self._process_input)
	escoria.inputs_manager.register_custom_input_handler(input_handler)

	_is_gamepad_connected = Input.is_joy_known(JOY_DEVICE)
	if _is_gamepad_connected:
		_on_gamepad_connected()

	Input.connect("joy_connection_changed", Callable(self, "_on_joy_connection_changed"))


func _exit_tree():
	escoria.inputs_manager.register_custom_input_handler(null)
	Input.disconnect("joy_connection_changed", Callable(self, "_on_joy_connection_changed"))
	if _is_gamepad_connected:
		_on_gamepad_disconnected()


func _input(event: InputEvent) -> void:
	super._input(event)
	if escoria.get_escoria().is_ready_for_inputs():
		if event is InputEventMouseMotion:
			_current_mouse_pos = get_global_mouse_position()
			update_tooltip_following_mouse_position()
		elif not event is InputEventMouseButton:
			# `velocity` will be a Vector2 between `Vector2(-1.0, -1.0)` and `Vector2(1.0, 1.0)`.
			# This handles deadzone in a correct way for most use cases.
			# The resulting deadzone will have a circular shape as it generally should.
			var velocity = Input.get_vector("esc_left", "esc_right", "esc_up", "esc_down")
			
			if velocity == Vector2.ZERO:
				escoria.object_manager.get_object("player").node.stop_walking()
			else:
				escoria.object_manager.get_object("player").node.walk_direction(velocity)
			
		#if event is InputEventKey:
			#if event.is_action("esc_left"):
				#key_left()
			#if event.is_action("esc_right"):
				#key_right()
			#if event.is_action("esc_up"):
				#key_up()
			#if event.is_action("esc_down"):
				#key_down()
			#if event.is_released():
				#escoria.object_manager.get_object("player").node.stop_walking()

# https://github.com/godotengine/godot-demo-projects/blob/3.4-585455e/misc/joypads/joypads.gd
# was informative in wiring up the gamepad properly.
func _on_gamepad_connected():
	set_physics_process(true)

	var primary_event = InputEventJoypadButton.new()
	primary_event.button_index = PRIMARY_ACTION_BUTTON
	InputMap.add_action(escoria.inputs_manager.ESC_UI_PRIMARY_ACTION)
	InputMap.action_add_event(escoria.inputs_manager.ESC_UI_PRIMARY_ACTION, primary_event)

	var verb_event = InputEventJoypadButton.new()
	verb_event.button_index = CHANGE_VERB_BUTTON
	InputMap.add_action(ESC_UI_CHANGE_VERB_ACTION)
	InputMap.action_add_event(ESC_UI_CHANGE_VERB_ACTION, verb_event)


func _on_gamepad_disconnected():
	InputMap.action_erase_events(escoria.inputs_manager.ESC_UI_PRIMARY_ACTION)
	InputMap.erase_action(escoria.inputs_manager.ESC_UI_PRIMARY_ACTION)

	InputMap.action_erase_events(ESC_UI_CHANGE_VERB_ACTION)
	InputMap.erase_action(ESC_UI_CHANGE_VERB_ACTION)

	set_physics_process(false)
	_is_gamepad_connected = false


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if device != JOY_DEVICE:
		return
	elif connected:
		_on_gamepad_connected()
	else:
		_on_gamepad_disconnected()


func _process(_delta) -> void:
	if !_is_gamepad_connected:
		return

	var x = Input.get_joy_axis(JOY_DEVICE, JOY_AXIS_LEFT_X)
	var y = Input.get_joy_axis(JOY_DEVICE, JOY_AXIS_LEFT_Y)
	var delta_x = int(x * AXIS_WEIGHT) if abs(x) > DEADZONE else 0
	var delta_y = int(y * AXIS_WEIGHT) if abs(y) > DEADZONE else 0
	if delta_x or delta_y:
		var direction: Vector2
		direction.x = delta_x
		direction.y = delta_y
		escoria.logger.trace(self, "gamepad direction: %s" % [direction])
		var viewport = get_viewport()
		viewport.warp_mouse(viewport.get_mouse_position() + direction)


func _process_input(event: InputEvent, is_default_state: bool) -> bool:
	if not is_default_state:
		# ESCBackground is not guaranteed to be set, as we may be on
		# the "New Game" screen.
		return false
	elif _is_gamepad_connected and event is InputEventJoypadButton:
		escoria.logger.trace(self, "InputEventJoypadButton: %s" % [event.as_text()])
		if event.is_action_pressed(escoria.inputs_manager.ESC_UI_PRIMARY_ACTION):
			# Admittedly, this breaks abstraction barriers and is completely
			# inappropriate, but it's what works right now.
			escoria.inputs_manager._on_left_click_on_bg(get_global_mouse_position())
			return true
		elif event.is_action_pressed(ESC_UI_CHANGE_VERB_ACTION):
			mousewheel_action(1)
			return true
	return false


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
		$mouse_layer/verbs_menu.action_manually_changed = false
	close_inventory()

func right_click_on_bg(position: Vector2) -> void:
	left_double_click_on_bg(position)

func left_double_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.action_manager.do(
			escoria.action_manager.ACTION.BACKGROUND_CLICK,
			[escoria.main.current_scene.player.global_id, position, true],
			true
		)
		$mouse_layer/verbs_menu.set_by_name(VERB_WALK)
		$mouse_layer/verbs_menu.clear_tool_texture()
		$mouse_layer/verbs_menu.action_manually_changed = false
	close_inventory()

## ITEM/HOTSPOT FOCUS ##

func element_focused(element_id: String) -> void:
	var target_obj: ESCItem = escoria.object_manager.get_object(element_id).node

	# This code is commented to demonstrate how to implement a simple hover
	# behaviour on an item.
	#if target_obj.has_method("get_sprite") and target_obj.get_sprite().texture:
		#targeted_node = target_obj.get_sprite()
		#targeted_node.modulate = Color.GRAY

	$ui/tooltip.set_target(target_obj.tooltip_name)

	if escoria.action_manager.current_action != VERB_USE \
			and escoria.action_manager.current_tool == null \
			and target_obj is ESCItem:

			if target_obj.is_exit:
				if element_id.contains("_l_"):
					$mouse_layer/verbs_menu.set_by_name("exit_left", "walk")
				elif element_id.contains("_r_"):
					$mouse_layer/verbs_menu.set_by_name("exit_right", "walk")
				else:
					$mouse_layer/verbs_menu.set_by_name("walk")
			elif not $mouse_layer/verbs_menu.action_manually_changed:
				$mouse_layer/verbs_menu.set_by_name(target_obj.default_action)

func element_unfocused() -> void:
	$ui/tooltip.set_target("")
	if not $mouse_layer/verbs_menu.action_manually_changed:
		$mouse_layer/verbs_menu.set_by_name("walk")


	# This code is commented to demonstrate how to implement a simple unhover
	# behaviour on an item.
	#if targeted_node != null:
		#targeted_node.modulate = Color.WHITE

## ITEMS ##
func left_click_on_item(item_global_id: String, event: InputEvent) -> void:
	var target_obj = escoria.object_manager.get_object(item_global_id).node

	# current_action will be empty if an event completes between when you stop
	# moving the mouse and when you click.
	if escoria.action_manager.current_action == "":
		if target_obj is ESCItem:
				$mouse_layer/verbs_menu.set_by_name(
					target_obj.default_action
				)

	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_LEFT_CLICK,
		[item_global_id, event],
		true
	)

	$mouse_layer/verbs_menu.clear_tool_texture()
	close_inventory()


func right_click_on_item(item_global_id: String, event: InputEvent) -> void:
	element_focused(item_global_id)
	var object = escoria.object_manager.get_object(item_global_id)
	if object != null:
		$mouse_layer/verbs_menu.set_by_name("look")
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

	if escoria.action_manager.current_action == VERB_USE:
		var object = escoria.object_manager.get_object(
			inventory_item_global_id
		)
		var item = object.node
		if item.has_method("get_sprite") and item.get_sprite().texture:
			$mouse_layer/verbs_menu.set_tool_texture(
				item.get_sprite().texture
			)
		elif item.inventory_item.texture_normal:
			$mouse_layer/verbs_menu.set_tool_texture(
				item.inventory_item.texture_normal
			)
		escoria.action_manager.current_tool = object

		if escoria.action_manager.current_target != null:
			$mouse_layer/verbs_menu.clear_tool_texture()
			$mouse_layer/verbs_menu.set_by_name(VERB_WALK)

func right_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	element_focused(inventory_item_global_id)
	var object = escoria.object_manager.get_object(inventory_item_global_id)
	if object != null:
		escoria.action_manager.set_current_action("look")
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_RIGHT_CLICK,
		[inventory_item_global_id, event],
		true
	)


func left_double_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	pass


func inventory_item_focused(inventory_item_global_id: String) -> void:
	if not $mouse_layer/verbs_menu.action_manually_changed:
		var item_node: ESCItem = escoria.object_manager.get_object(
				inventory_item_global_id
			).node
		$ui/tooltip.set_target(item_node.tooltip_name)
		$mouse_layer/verbs_menu.set_by_name(item_node.default_action_inventory)


func inventory_item_unfocused() -> void:
	$ui/tooltip.clear()
	if escoria.action_manager.current_action == VERB_WALK:
		$mouse_layer/verbs_menu.set_by_name(VERB_WALK)
		if $mouse_layer/verbs_menu.action_manually_changed:
			$mouse_layer/verbs_menu.action_manually_changed = false
	elif not $mouse_layer/verbs_menu.action_manually_changed \
			and escoria.action_manager.current_tool == null:
		$mouse_layer/verbs_menu.set_by_name(VERB_WALK)


func open_inventory():
	$ui/inventory_ui.show_inventory()


func close_inventory():
	$ui/inventory_ui.hide_inventory()


func mousewheel_action(direction: int):
	$mouse_layer/verbs_menu.iterate_actions_cursor(direction)


func hide_ui():
	$ui/inventory_ui.propagate_call("set_visible", [false], true)
	$ui/tooltip.propagate_call("set_visible", [false], true)
	$ui/HBoxContainer/VBoxContainer.visible = false
	$ui/HBoxContainer/VBoxContainer/MenuButton.visible = false


func show_ui():
	$ui/inventory_ui.propagate_call("set_visible", [true], true)
	$ui/tooltip.propagate_call("set_visible", [true], true)
	$ui/HBoxContainer/VBoxContainer.visible = true
	$ui/HBoxContainer/VBoxContainer/MenuButton.visible = true


func hide_main_menu():
	show_ui()
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	if get_node(main_menu).visible:
		get_node(main_menu).hide()

func show_main_menu():
	if escoria.current_state == escoria.GAME_STATE.PAUSED:
		return
	escoria.current_state = escoria.GAME_STATE.PAUSED
	hide_ui()
	if not get_node(main_menu).visible:
		get_node(main_menu).reset()
		get_node(main_menu).show()

func unpause_game():
	show_ui()
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	if get_node(pause_menu).visible:
		get_node(pause_menu).hide()
		escoria.object_manager.get_object(ESCObjectManager.SPEECH).node.resume()
		escoria.main.current_scene.game.show_ui()
		escoria.main.current_scene.show()
		escoria.set_game_paused(false)

func pause_game():
	if escoria.current_state == escoria.GAME_STATE.PAUSED:
		return
	show_ui()
	escoria.current_state = escoria.GAME_STATE.PAUSED
	if not get_node(pause_menu).visible:
		get_node(main_menu).reset()
		get_node(pause_menu).reset()
		get_node(pause_menu).set_save_enabled(
			escoria.save_manager.save_enabled
		)
		get_node(pause_menu).show()
		escoria.object_manager.get_object(ESCObjectManager.SPEECH).node.pause()
		escoria.main.current_scene.game.hide_ui()
		escoria.main.current_scene.hide()
		escoria.set_game_paused(true)


func apply_custom_settings(custom_settings: Dictionary):
	if custom_settings.has("a_custom_setting"):
		escoria.logger.info(
			self,
			"custom setting value loaded: %s."
					% str(custom_settings["a_custom_setting"])
		)


func get_custom_data() -> Dictionary:
	return {
		"ui_type": "simplemouse"
	}


# Update the tooltip
func update_tooltip_following_mouse_position():
	_current_mouse_pos = get_global_mouse_position()
	var corrected_position = _current_mouse_pos \
		+ Vector2(32, -tooltip_node.size.y/2)

	# clamp TOP
	if tooltip_node.tooltip_distance_to_edge_top(_current_mouse_pos) <= mouse_tooltip_margin:
		corrected_position.y = mouse_tooltip_margin

	# clamp BOTTOM
	if tooltip_node.tooltip_distance_to_edge_bottom(_current_mouse_pos + tooltip_node.size) <= mouse_tooltip_margin:
		corrected_position.y = escoria.game_size.y - mouse_tooltip_margin - tooltip_node.size.y

	# clamp LEFT
	if tooltip_node.tooltip_distance_to_edge_left(_current_mouse_pos - tooltip_node.size/2) <= mouse_tooltip_margin:
		corrected_position.x = mouse_tooltip_margin

	# clamp RIGHT
	if tooltip_node.tooltip_distance_to_edge_right(_current_mouse_pos + tooltip_node.size/2) <= mouse_tooltip_margin:
		corrected_position.x = escoria.game_size.x - mouse_tooltip_margin - tooltip_node.size.x

	tooltip_node.position = corrected_position + tooltip_node.offset_from_cursor


func _on_action_finished():
	$mouse_layer/verbs_menu.clear_tool_texture()
	$mouse_layer/verbs_menu.iterate_actions_cursor(0)


func _on_event_done(_return_code: int, _event_name: String):
	if _return_code == ESCExecution.RC_OK:
		escoria.action_manager.clear_current_action()
		$ui/tooltip.set_target("")
		$mouse_layer/verbs_menu.set_by_name(VERB_WALK)



func _on_MenuButton_pressed() -> void:
	pause_game()
