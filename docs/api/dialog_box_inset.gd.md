<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# dialog\_box\_inset.gd

**Extends:** [PanelContainer](../PanelContainer)

## Description

## Property Descriptions

### current\_character

```gdscript
export var current_character = ""
```

- **Setter**: `set_current_character`

### avatar\_node

```gdscript
var avatar_node
```

### name\_node

```gdscript
var name_node
```

### text\_node

```gdscript
var text_node
```

### tween

```gdscript
var tween
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
export var max_time_to_text_disappear = 1
```

## Method Descriptions

### set\_current\_character

```gdscript
func set_current_character(name: String)
```

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
