<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCInventoryContainer

**Extends:** [Control](../Control)

## Description

Inventory container handler that acts as a base for UIs inventory containers

## Method Descriptions

### is\_empty

```gdscript
func is_empty() -> bool
```

Get wether the inventory container currently is empty
**Returns** Wether the container is empty or not

### add\_item

```gdscript
func add_item(inventory_item: ESCInventoryItem) -> ESCInventoryButton
```

Add a new item into the container and return the control generated for it
so its events can be handled by the inputs manager

#### Parameters
- inventory_item: Item to add
**Returns** The button generated for the item

### remove\_item

```gdscript
func remove_item(inventory_item: ESCInventoryItem)
```

Remove an item from the container

#### Parameters
- inventory_item: Item to remove