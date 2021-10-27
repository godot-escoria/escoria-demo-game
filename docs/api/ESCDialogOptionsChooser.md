<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCDialogOptionsChooser

**Extends:** [Control](../Control)

## Description

Base class for all dialog options implementations

## Property Descriptions

### dialog

```gdscript
var dialog: ESCDialog
```

The dialog to show

## Method Descriptions

### set\_dialog

```gdscript
func set_dialog(new_dialog: ESCDialog) -> void
```

Set the dialog used for the chooser

#### Parameters

- new_dialog: Dialog to set

### show\_chooser

```gdscript
func show_chooser() -> void
```

Show the dialog chooser UI

### hide\_chooser

```gdscript
func hide_chooser() -> void
```

Hide the dialog chooser UI

## Signals

- signal option_chosen(option): An option was chosen

##### Parameters

- option: The dialog option that was chosen
