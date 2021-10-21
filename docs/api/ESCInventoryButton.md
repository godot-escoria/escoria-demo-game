<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCInventoryButton

**Extends:** [TextureButton](../TextureButton)

## Description

The inventory representation of an ESC item if pickable (only used by
the inventory components)

## Property Descriptions

### global\_id

```gdscript
var global_id: String = ""
```

Global ID of the ESCItem that uses this ESCInventoryItem

## Method Descriptions

### \_init

```gdscript
func _init(p_item: ESCInventoryItem) -> void
```

## Signals

- signal mouse_left_inventory_item(item_id): Signal emitted when the item was left clicked

#### Parameters

- item_id: Global ID of the clicked item
- signal mouse_right_inventory_item(item_id): Signal emitted when the item was right clicked

#### Parameters

- item_id: Global ID of the clicked item
- signal mouse_double_left_inventory_item(item_id): Signal emitted when the item was double clicked

#### Parameters

- item_id: Global ID of the clicked item
- signal inventory_item_focused(item_id): Signal emitted when the item was focused

#### Parameters

- item_id: Global ID of the clicked item
- signal inventory_item_unfocused(): Signal emitted when the item is not focused anymore
