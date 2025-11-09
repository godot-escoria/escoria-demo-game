## The inventory representation of an ESC item if pickable (only used by
## the inventory components)
extends TextureButton
class_name ESCInventoryButton

## Signal emitted when the item was left clicked.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item_id|`Variant`|Global ID of the clicked item|yes|[br]
## [br]
signal mouse_left_inventory_item(item_id)

## Signal emitted when the item was right clicked.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item_id|`Variant`|Global ID of the clicked item|yes|[br]
## [br]
signal mouse_right_inventory_item(item_id)

## Signal emitted when the item was double clicked.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item_id|`Variant`|Global ID of the clicked item|yes|[br]
## [br]
signal mouse_double_left_inventory_item(item_id)

## Signal emitted when the item was focused.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item_id|`Variant`|Global ID of the clicked item|yes|[br]
## [br]
signal inventory_item_focused(item_id)

## Signal emitted when the item is not focused anymore.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
signal inventory_item_unfocused()

## Global ID of the ESCItem that uses this ESCInventoryItem.
var global_id: String = ""



## Initializes the inventory button with the given item.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_item|`ESCInventoryItem`|The ESCInventoryItem to represent.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _init(p_item: ESCInventoryItem) -> void:
	global_id = p_item.global_id
	texture_normal = p_item.texture_normal
	texture_hover = p_item.texture_hovered
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT



## Updates the size of the inventory button every frame.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |_delta|`float`|The frame time delta (unused).|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _process(_delta: float) -> void:
	size = ProjectSettings.get_setting("escoria/ui/inventory_item_size")
	custom_minimum_size = ProjectSettings.get_setting(
		"escoria/ui/inventory_item_size"
	)


## Connects input handlers for the inventory button.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _ready():
	gui_input.connect(_on_inventory_item_gui_input)
	mouse_entered.connect(_on_inventory_item_mouse_enter)
	mouse_exited.connect(_on_inventory_item_mouse_exit)



## Handles the gui input and emits the respective signals.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |event|`InputEvent`|The event received.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _on_inventory_item_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			escoria.inputs_manager._on_mousewheel_action(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			escoria.inputs_manager._on_mousewheel_action(1)
			get_viewport().set_input_as_handled()
		elif event.double_click:
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


## Handles mouse entering the item and sends the respective signal.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _on_inventory_item_mouse_enter():
	inventory_item_focused.emit(global_id)

## Handles mouse leaving the item and sends the respective signal.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _on_inventory_item_mouse_exit():
	inventory_item_unfocused.emit()
