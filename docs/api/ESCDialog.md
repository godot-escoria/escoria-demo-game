<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCDialog

**Extends:** [ESCStatement](../ESCStatement) < [Object](../Object)

## Description

An ESC dialog

## Constants Descriptions

### END\_REGEX

```gdscript
const END_REGEX: String = "^(?<indent>\\s*)!.*$"
```

A Regex that matches the end of a dialog

### REGEX

```gdscript
const REGEX: String = "^(\\s*)\\?( (?<avatar>[^ ]+))?( (?<timeout>[^ ]+))?( (?<timeout_option>.+))?$"
```

Regex that matches dialog lines

## Property Descriptions

### avatar

```gdscript
var avatar: String = "-"
```

Avatar used in the dialog

### timeout

```gdscript
var timeout: int = 0
```

Timeout until the timeout_option option is selected. Use 0 for no timeout

### timeout\_option

```gdscript
var timeout_option: int = 0
```

The dialog option to select when timeout is reached

### options

```gdscript
var options: Array
```

A list of ESCDialogOptions

## Method Descriptions

### \_init

```gdscript
func _init(dialog_string: String)
```

Construct a dialog from a dialog string

### is\_valid

```gdscript
func is_valid() -> bool
```

Check if dialog is valid

### run

```gdscript
func run()
```

Run this dialog