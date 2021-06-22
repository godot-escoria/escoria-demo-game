<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCEvent

**Extends:** [ESCStatement](../ESCStatement) < [Object](../Object)

## Description

An event in the ESC language

Events are triggered from various sources. Common events include

* :setup Called every time when visiting a scene
* :ready Called the first time a scene is visited
* :use <global id> Called from the current item when it is used with the item
  with the global id <global id>

## Constants Descriptions

### FLAG\_CUT\_BLACK

```gdscript
const FLAG_CUT_BLACK: int = 16
```

### FLAG\_LEAVE\_BLACK

```gdscript
const FLAG_LEAVE_BLACK: int = 32
```

### FLAG\_NO\_HUD

```gdscript
const FLAG_NO_HUD: int = 4
```

### FLAG\_NO\_SAVE

```gdscript
const FLAG_NO_SAVE: int = 8
```

### FLAG\_NO\_TT

```gdscript
const FLAG_NO_TT: int = 2
```

### FLAG\_TK

```gdscript
const FLAG_TK: int = 1
```

### REGEX

```gdscript
const REGEX: String = "^:(?<name>[^|]+)( \\|(?<flags>( (TK|NO_TT|NO_HUD|NO_SAVE|CUT_BLACK|LEAVE_BLACK))+))?$"
```

Regex identifying an ESC event

## Property Descriptions

### name

```gdscript
var name: String
```

Name of event

### flags

```gdscript
var flags: int = 0
```

Flags set to this event

## Method Descriptions

### \_init

```gdscript
func _init(event_string: String)
```

Create a new event from an event line

### run

```gdscript
func run() -> int
```

Execute this statement and return its return code