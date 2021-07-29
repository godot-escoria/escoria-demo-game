<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# dialog\_label.gd

**Extends:** [RichTextLabel](../RichTextLabel)

## Description

A dialog UI using a label above the head of the character

## Property Descriptions

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
export var max_time_to_text_disappear = 2
```

The time to wait before the dialog is finished

### current\_character

```gdscript
var current_character
```

Current character speaking, to keep track of reference for animation purposes

### tween

```gdscript
var tween
```

Tween node for text animation

### text\_node

```gdscript
var text_node
```

The node showing the text

## Method Descriptions

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
