<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCCondition

**Extends:** [Object](../Object)

## Description

A condition to run a command

## Constants Descriptions

### COMPARISON\_ACTIVITY

```gdscript
const COMPARISON_ACTIVITY: int = 4
```

### COMPARISON\_DESCRIPTION

```gdscript
const COMPARISON_DESCRIPTION: Array = ["Checking if %s %s %s true%s","Checking if %s %s %s equals %s","Checking if %s %s %s greater than %s","Checking if %s %s %s less than %s","Checking if %s is %s active%s"]
```

### COMPARISON\_EQ

```gdscript
const COMPARISON_EQ: int = 1
```

### COMPARISON\_GT

```gdscript
const COMPARISON_GT: int = 2
```

### COMPARISON\_LT

```gdscript
const COMPARISON_LT: int = 3
```

### COMPARISON\_NONE

```gdscript
const COMPARISON_NONE: int = 0
```

### REGEX

```gdscript
const REGEX: String = "^(?<is_negated>!)?(?<comparison>eq|gt|lt)? ?(?<is_inventory>i/)?(?<is_activity>a/)?(?<flag>[^ ]+)( (?<comparison_value>.+))?$"
```

Regex that matches condition lines

## Property Descriptions

### flag

```gdscript
var flag: String
```

Name of the flag compared

### negated

```gdscript
var negated: bool = false
```

Wether this condition is negated

### inventory

```gdscript
var inventory: bool = false
```

Wether this condition is regarding an inventory item ("i/...")

### comparison

```gdscript
var comparison: int
```

An optional comparison type. Use the COMPARISON-Enum

### comparison\_value

```gdscript
var comparison_value
```

The value used together with the comparison type

## Method Descriptions

### \_init

```gdscript
func _init(comparison_string: String)
```

Create a new condition from an ESC condition string

### run

```gdscript
func run() -> bool
```

Run this comparison against the globals