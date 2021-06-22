<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# dialog\_label.gd

**Extends:** [RichTextLabel](../RichTextLabel)

## Description

## Property Descriptions

### tween

```gdscript
var tween
```

### text\_node

```gdscript
var text_node
```

### text\_speed\_per\_character

```gdscript
export var text_speed_per_character = 0.1
```

### fast\_text\_speed\_per\_character

```gdscript
export var fast_text_speed_per_character = 0.25
```

### max\_time\_to\_text\_disappear

```gdscript
export var max_time_to_text_disappear = 2
```

### current\_character

```gdscript
var current_character
```

Current character speaking, to keep track of reference for animation purposes

## Method Descriptions

### say

```gdscript
func say(character: String, params: Dictionary)
```

### finish\_fast

```gdscript
func finish_fast()
```

## Signals

- signal dialog_line_started(): 
- signal dialog_line_finished(): 
