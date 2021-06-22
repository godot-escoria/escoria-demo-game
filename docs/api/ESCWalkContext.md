<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCWalkContext

**Extends:** [Object](../Object)

## Description

The walk context describes the target of a walk command and if that command
should be executed fast

## Property Descriptions

### target\_object

```gdscript
var target_object: ESCObject
```

Target object that the walk command tries to reach

### target\_position

```gdscript
var target_position: Vector2 = "(0, 0)"
```

The target position

### fast

```gdscript
var fast: bool
```

Wether to move fast

## Method Descriptions

### \_init

```gdscript
func _init(p_target_object: ESCObject, p_target_position: Vector2, p_fast: bool)
```

