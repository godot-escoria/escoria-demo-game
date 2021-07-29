<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# dialog\_box\_inset.gd

**Extends:** [PanelContainer](../PanelContainer)

## Description

A dialog GUI showing a dialog box and character portraits

## Property Descriptions

### current\_character

```gdscript
export var current_character = ""
```

- **Setter**: `set_current_character`

The currently speaking character

### text\_speed\_per\_character

```gdscript
export var text_speed_per_character = 0.1
```

The text speed per character for normal display

### fast\_text\_speed\_per\_character

```gdscript
export var fast_text_speed_per_character = 0.25
```

The text speed per character if the dialog line is skipped

### max\_time\_to\_text\_disappear

```gdscript
export var max_time_to_text_disappear = 1
```

The time to wait before the dialog is finished

### avatar\_node

```gdscript
var avatar_node
```

The node holding the avatar

### name\_node

```gdscript
var name_node
```

The node holding the player name

### text\_node

```gdscript
var text_node
```

The node showing the text

### tween

```gdscript
var tween
```

The tween node for text animations

## Method Descriptions

### set\_current\_character

```gdscript
func set_current_character(name: String)
```

Switch the current character

#### Parameters
- name: The name of the current character

### say

```gdscript
func say(character: String, line: String)
```

Make a character say something

#### Parameters
- character: The global id of the character speaking
- line: Line to say

### finish\_fast

```gdscript
func finish_fast()
```

Called by the dialog player when the

## Signals

- signal dialog_line_started(): Signal emitted when a dialog line has started
- signal dialog_line_finished(): Signal emitted when a dialog line has finished
