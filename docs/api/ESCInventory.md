<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCInventory

**Extends:** [Control](../Control)

## Description

Manages the inventory on the GUI connected to the inventory_ui_container
variable

## Property Descriptions

### inventory\_ui\_container

```gdscript
export var inventory_ui_container = ""
```

Define the actual container node to add items as children of.
Should be a Container.

### items\_ids\_in\_inventory

```gdscript
var items_ids_in_inventory: Dictionary
```

A registry of inventory ESCInventoryItem nodes

### inventory\_visible

```gdscript
var inventory_visible: bool = false
```

Wether the inventory is visible currently

## Method Descriptions

### add\_new\_item\_by\_id

```gdscript
func add_new_item_by_id(item_id: String) -> void
```

add item to Inventory UI using its id set in its scene

### remove\_item\_by\_id

```gdscript
func remove_item_by_id(item_id: String) -> void
```

remove item fromInventory UI using its id set in its scene

### show\_inventory

```gdscript
func show_inventory()
```

### hide\_inventory

```gdscript
func hide_inventory()
```

