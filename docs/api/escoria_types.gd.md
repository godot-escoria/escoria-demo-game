<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# escoria\_types.gd

**Extends:** [Node](../Node)

## Description

Escoria basic types

## Enumerations

### EVENT\_LEVEL\_STATE

```gdscript
const EVENT_LEVEL_STATE: Dictionary = {"BREAK":2,"CALL":4,"JUMP":5,"REPEAT":3,"RETURN":0,"YIELD":1}
```

ESC script states
RETURN - The ESC script has been completed successfully
YIELD - ESC is waiting for Godot to finish something (e.g. Sprite animation)
BREAK - ESC has completed the current command block. Jump back
REPEAT - ESC is repeating a command block
CALL - Call another ESC command block
JUMP - Jump to another ESC label

## Constants Descriptions

### OBJ\_DEFAULT\_STATE

```gdscript
const OBJ_DEFAULT_STATE: String = "default"
```

The default state of an object

## Sub\-classes

### ESCState

#### Property Descriptions

### file

```gdscript
var file
```

File or Dictionary

### line

```gdscript
var line
```

String, can be null

### indent

```gdscript
var indent: int
```

### line\_count

```gdscript
var line_count: int
```

#### Method Descriptions

### \_init

```gdscript
func _init(p_file, p_line, p_indent, p_line_count)
```

### ESCEvent

#### Property Descriptions

### ev\_name

```gdscript
var ev_name: String
```

### ev\_level

```gdscript
var ev_level: Array
```

### ev\_flags

```gdscript
var ev_flags: Array
```

#### Method Descriptions

### \_init

```gdscript
func _init(p_name, p_level, p_flags)
```

### ESCCommand

#### Property Descriptions

### name

```gdscript
var name: String
```

### params

```gdscript
var params: Array
```

### conditions

```gdscript
var conditions: Dictionary
```

### flags

```gdscript
var flags: Array
```

#### Method Descriptions

### \_init

```gdscript
func _init(p_name)
```

