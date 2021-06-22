<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCInventoryManager

**Extends:** [Object](../Object)

## Description

A manager for inventory objects

## Method Descriptions

### inventory\_has

```gdscript
func inventory_has(item: String) -> bool
```

Check if the player has an inventory item

#### Parameters

- item: Inventory item id
**Returns** Wether the player has the inventory

### items\_in\_inventory

```gdscript
func items_in_inventory() -> Array
```

Get all inventory items
**Returns** The items in the inventory

### remove\_item

```gdscript
func remove_item(item: String)
```

Remove an item from the inventory

#### Parameters

- item: Inventory item id

### add\_item

```gdscript
func add_item(item: String)
```

Add an item to the inventory

#### Parameters

- item: Inventory item id