# The inventory representation of an ESC item if pickable (only used by
# the inventory components)
extends TextureButton
class_name ESCInventoryButton


# Signal emitted when the item was left clicked
#
# #### Parameters
#
# - item_id: Global ID of the clicked item
signal mouse_left_inventory_item(item_id)

# Signal emitted when the item was right clicked
#
# #### Parameters
#
# - item_id: Global ID of the clicked item
signal mouse_right_inventory_item(item_id)

# Signal emitted when the item was double clicked
#
# #### Parameters
#
# - item_id: Global ID of the clicked item
signal mouse_double_left_inventory_item(item_id)

# Signal emitted when the item was focused
#
# #### Parameters
#
# - item_id: Global ID of the clicked item
signal inventory_item_focused(item_id)

# Signal emitted when the item is not focused anymore
signal inventory_item_unfocused()


# Global ID of the ESCItem that uses this ESCInventoryItem
var global_id: String = ""


func _init(p_item: ESCInventoryItem) -> void:
	global_id = p_item.global_id
	texture_normal = p_item.texture_normal
	texture_hover = p_item.texture_hovered
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT


func _process(_delta: float) -> void:
	size = ProjectSettings.get_setting("escoria/ui/inventory_item_size")
	custom_minimum_size = ProjectSettings.get_setting(
		"escoria/ui/inventory_item_size"
	)

# Connect input handlers
func _ready():
	gui_input.connect(_on_inventory_item_gui_input)
	mouse_entered.connect(_on_inventory_item_mouse_enter)
	mouse_exited.connect(_on_inventory_item_mouse_exit)


# Handle the gui input and emit the respective signals
#
# #### Parameters
#
# - event: The event received
func _on_inventory_item_gui_input(event: InputEvent):
	if InputMap.has_action("switch_action_verb") \
			and event.is_action_pressed("switch_action_verb"):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			escoria.inputs_manager._on_mousewheel_action(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			escoria.inputs_manager._on_mousewheel_action(1)
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
#		var p = get_global_mouse_position()
		if event.double_click:
			if event.button_index == MOUSE_BUTTON_LEFT:
				mouse_double_left_inventory_item.emit(
					global_id,
					event
				)
			# Make sure fast right clicks in the inventory aren't ignored
			elif event.button_index == MOUSE_BUTTON_RIGHT:
					mouse_right_inventory_item.emit(
						global_id,
						event
					)
		else:
			if event.is_pressed():
				if event.button_index == MOUSE_BUTTON_LEFT:
					mouse_left_inventory_item.emit(
						global_id,
						event
					)
				if event.button_index == MOUSE_BUTTON_RIGHT:
					mouse_right_inventory_item.emit(
						global_id,
						event
					)


# Handle mouse entering the item and send the respecitve signal
func _on_inventory_item_mouse_enter():
	inventory_item_focused.emit(global_id)

# Handle mouse leaving the item and send the respecitve signal
func _on_inventory_item_mouse_exit():
	inventory_item_unfocused.emit()
