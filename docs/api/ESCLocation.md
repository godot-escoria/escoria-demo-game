<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCLocation

**Extends:** [Position2D](../Position2D)

## Description

 A simple node extending Position2D with a global ID so that it can be
referenced in ESC Scripts.

## Property Descriptions

### global\_id

```gdscript
export var global_id = ""
```

The global ID of this item

### is\_start\_location

```gdscript
export var is_start_location = false
```

If true, this ESCLocation is considered as a player start location

### player\_orients\_on\_arrival

```gdscript
export var player_orients_on_arrival = true
```

If true, player orients towards 'interaction_direction' as
player character arrives.

### interaction\_direction

```gdscript
export var interaction_direction = 0
```

Let the player turn to this direction when the player arrives
at the item

## Method Descriptions

### is\_class

```gdscript
func is_class(p_classname: String) -> bool
```

Used by "is" keyword to check whether a node's class_name
is the same as p_classname.

## Parameters

p_classname: String class to compare against