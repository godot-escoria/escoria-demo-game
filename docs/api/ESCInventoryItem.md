<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCInventoryItem

**Extends:** [TextureButton](../TextureButton)

## Description

The inventory representation of an ESC item if pickable

## Property Descriptions

### global\_id

```gdscript
var global_id
```

Global ID of the ESCItem that uses this ESCInventoryItem
Will be set by ESCItem automatically

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
