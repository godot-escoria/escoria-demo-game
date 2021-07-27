<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCObject

**Extends:** [Node](../Node)

## Description

An object handled in Escoria

## Property Descriptions

### global\_id

```gdscript
var global_id: String
```

The global id of the object

### active

```gdscript
var active: bool = true
```

Wether the object is active (visible to the player)

### interactive

```gdscript
var interactive: bool = true
```

Wether the object is interactive (clickable by the player)

### state

```gdscript
var state: String = "default"
```

The state of the object. If the object has a respective animation,
it will be played

### events

```gdscript
var events: Dictionary
```

The events registered with the object

### node

```gdscript
var node: Node
```

The node in the scene. Can be an ESCItem or an ESCCamera

## Method Descriptions

### \_init

```gdscript
func _init(p_global_id: String, p_node: Node)
```

### set\_state

```gdscript
func set_state(p_state: String, immediate: bool = false)
```

Set the state and start a possible animation

#### Parameters

- p_state: State to set
- immediate: If true, skip directly to the end

### get\_save\_data

```gdscript
func get_save_data() -> Dictionary
```

Return the data of the object to be inserted in a savegame file.

**Returns**
A dictionary containing the data to be saved for this object.