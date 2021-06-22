<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCGroup

**Extends:** [ESCStatement](../ESCStatement) < [Object](../Object)

## Description

A group of ESC commands

## Constants Descriptions

### REGEX

```gdscript
const REGEX: String = "^([^>]*)>\\s*(\\[(?<conditions>[^\\]]+)\\])?$"
```

A RegEx identifying a group

## Property Descriptions

### conditions

```gdscript
var conditions: Array
```

A list of ESCConditions to run this group
Conditions are combined using logical AND

## Method Descriptions

### \_init

```gdscript
func _init(group_string: String)
```

Construct an ESC group of an ESC script line