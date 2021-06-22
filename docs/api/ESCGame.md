<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCGame

**Extends:** [Node2D](../Node2D)

## Description

A base class for ESC game scenes
An extending class can be used in the project settings and is responsible
for managing very basic game features and controls

## Enumerations

### EDITOR\_GAME\_DEBUG\_DISPLAY

```gdscript
const EDITOR_GAME_DEBUG_DISPLAY: Dictionary = {"MOUSE_TOOLTIP_LIMITS":1,"NONE":0}
```

Editor debug modes
NONE - No debugging
MOUSE_TOOLTIP_LIMITS - Visualize the tooltip limits

## Property Descriptions

### mouse\_tooltip\_margin

```gdscript
export var mouse_tooltip_margin = 50
```

The safe margin around tooltips

### tooltip\_node

```gdscript
var tooltip_node: Object
```

A reference to the node handling tooltips

### editor\_debug\_mode

```gdscript
export var editor_debug_mode = 0
```

Which (if any) debug mode for the editor is used

## Method Descriptions

### left\_click\_on\_bg

```gdscript
func left_click_on_bg(position: Vector2) -> void
```

Called when the player left clicks on the background
(Needs to be overridden, if supported)

#### Parameters

- position: Position clicked

### right\_click\_on\_bg

```gdscript
func right_click_on_bg(position: Vector2) -> void
```

Called when the player right clicks on the background
(Needs to be overridden, if supported)

#### Parameters

- position: Position clicked

### left\_double\_click\_on\_bg

```gdscript
func left_double_click_on_bg(position: Vector2) -> void
```

Called when the player double clicks on the background
(Needs to be overridden, if supported)

#### Parameters

- position: Position clicked

### element\_focused

```gdscript
func element_focused(element_id: String) -> void
```

Called when an element in the scene was focused
(Needs to be overridden, if supported)

#### Parameters

- element_id: Global id of the element focused

### element\_unfocused

```gdscript
func element_unfocused() -> void
```

Called when no element is focused anymore
(Needs to be overridden, if supported)

### left\_click\_on\_item

```gdscript
func left_click_on_item(item_global_id: String, event: InputEvent) -> void
```

Called when an item was left clicked
(Needs to be overridden, if supported)

#### Parameters

- item_global_id: Global id of the item that was clicked
- event: The received input event

### right\_click\_on\_item

```gdscript
func right_click_on_item(item_global_id: String, event: InputEvent) -> void
```

Called when an item was right clicked
(Needs to be overridden, if supported)

#### Parameters

- item_global_id: Global id of the item that was clicked
- event: The received input event

### left\_double\_click\_on\_item

```gdscript
func left_double_click_on_item(item_global_id: String, event: InputEvent) -> void
```

### left\_click\_on\_inventory\_item

```gdscript
func left_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void
```

### right\_click\_on\_inventory\_item

```gdscript
func right_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void
```

### left\_double\_click\_on\_inventory\_item

```gdscript
func left_double_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void
```

### inventory\_item\_focused

```gdscript
func inventory_item_focused(inventory_item_global_id: String) -> void
```

Called when an inventory item was focused
(Needs to be overridden, if supported)

#### Parameters

- inventory_item_global_id: Global id of the inventory item that was focused

### inventory\_item\_unfocused

```gdscript
func inventory_item_unfocused() -> void
```

Called when no inventory item is focused anymore
(Needs to be overridden, if supported)

### open\_inventory

```gdscript
func open_inventory()
```

Called when the inventory was opened
(Needs to be overridden, if supported)

### close\_inventory

```gdscript
func close_inventory()
```

Called when the inventory was closed
(Needs to be overridden, if supported)

### mousewheel\_action

```gdscript
func mousewheel_action(direction: int)
```

Called when the mousewheel was used
(Needs to be overridden, if supported)

#### Parameter

- direction: The direction in which the mouse wheel was rotated

### hide\_ui

```gdscript
func hide_ui()
```

Called when the UI should be hidden
(Needs to be overridden, if supported)

### show\_ui

```gdscript
func show_ui()
```

Called when the UI should be shown
(Needs to be overridden, if supported)

### update\_tooltip\_following\_mouse\_position

```gdscript
func update_tooltip_following_mouse_position(p_position: Vector2)
```

Function is called if Project setting escoria/ui/tooltip_follows_mouse = true

#### Parameters

- p_position: Position of the mouse