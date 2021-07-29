<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCInputsManager

**Extends:** [Node](../Node)

## Description

Escoria inputs manager
Catches, handles and distributes input events for the game

## Constants Descriptions

### INPUT\_ALL

```gdscript
const INPUT_ALL: int = 0
```

### INPUT\_NONE

```gdscript
const INPUT_NONE: int = 1
```

### INPUT\_SKIP

```gdscript
const INPUT_SKIP: int = 2
```

## Property Descriptions

### input\_mode

```gdscript
var input_mode
```

The current input mode

### hover\_stack

```gdscript
var hover_stack: Array
```

A LIFO stack of hovered items

### hotspot\_focused

```gdscript
var hotspot_focused: String = ""
```

The global id fo the topmost item from the hover_stack