<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCCommandArgumentDescriptor

**Extends:** [Object](../Object)

## Description

The descriptor of the arguments of an ESC command

## Property Descriptions

### min\_args

```gdscript
var min_args: int = 0
```

Number of arguments the command expects

### types

```gdscript
var types: Array
```

The types the arguments as TYPE_ constants. If the command is called with
more arguments than there are entries in the types array, the additional
arguments will be checked against the last entry of the types array.

### defaults

```gdscript
var defaults: Array
```

The default values for the arguments

## Method Descriptions

### \_init

```gdscript
func _init(p_min_args: int = 0, p_types: Array, p_defaults: Array)
```

Initialize the descriptor

### prepare\_arguments

```gdscript
func prepare_arguments(arguments: Array) -> Array
```

Combine the default argument values with the given arguments

### validate

```gdscript
func validate(command: String, arguments: Array) -> bool
```

Validate wether the given arguments match the command descriptor