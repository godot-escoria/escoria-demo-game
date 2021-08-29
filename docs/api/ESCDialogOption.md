<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCDialogOption

**Extends:** [ESCStatement](../ESCStatement) < [Object](../Object)

## Description

An option of an ESC dialog

## Constants Descriptions

### REGEX

```gdscript
const REGEX: String = "^[^-]*- (?<trans_key>[^:]+)?:?\"(?<option>[^\"]+)\"( \\[(?<conditions>[^\\]]+)\\])?$"
```

Regex that matches dialog option lines

## Property Descriptions

### option

```gdscript
var option: String
```

- **Getter**: `get_option`

Option displayed in the HUD

### conditions

```gdscript
var conditions: Array
```

Conditions to show this dialog

## Method Descriptions

### \_init

```gdscript
func _init(option_string: String)
```

Create a dialog option from a string

### get\_option

```gdscript
func get_option()
```

### is\_valid

```gdscript
func is_valid() -> bool
```

Check, if conditions match