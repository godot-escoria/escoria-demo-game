<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCTooltip

**Extends:** [RichTextLabel](../RichTextLabel)

## Description

## Constants Descriptions

### MAX\_HEIGHT

```gdscript
const MAX_HEIGHT: int = 500
```

### MAX\_WIDTH

```gdscript
const MAX_WIDTH: int = 200
```

### MIN\_HEIGHT

```gdscript
const MIN_HEIGHT: int = 30
```

### ONE\_LINE\_HEIGHT

```gdscript
const ONE_LINE_HEIGHT: int = 16
```

## Property Descriptions

### current\_action

```gdscript
var current_action: String
```

Infinitive verb

### current\_target

```gdscript
var current_target: String
```

- **Setter**: `set_target`

Target item/hotspot

### current\_prep

```gdscript
var current_prep: String = "with"
```

Preposition: on, with...

### current\_target2

```gdscript
var current_target2: String
```

Target 2 item/hotspot

### waiting\_for\_target2

```gdscript
var waiting_for_target2
```

True if tooltip is waiting for a click on second target (use x with y)

### color

```gdscript
export var color = "0,0,0,1"
```

- **Setter**: `set_color`

### offset\_from\_cursor

```gdscript
export var offset_from_cursor = "(10, 0)"
```

### debug\_mode

```gdscript
export var debug_mode = false
```

- **Setter**: `set_debug_mode`

### debug\_texturerect\_node

```gdscript
var debug_texturerect_node: TextureRect
```

## Method Descriptions

### get\_class

```gdscript
func get_class()
```

### set\_color

```gdscript
func set_color(p_color: Color)
```

### set\_debug\_mode

```gdscript
func set_debug_mode(p_debug_mode: bool)
```

### on\_action\_selected

```gdscript
func on_action_selected() -> void
```

### set\_target

```gdscript
func set_target(target: String, needs_second_target: bool = false) -> void
```

### set\_target2

```gdscript
func set_target2(target2: String) -> void
```

### update\_tooltip\_text

```gdscript
func update_tooltip_text()
```

### update\_size

```gdscript
func update_size()
```

### tooltip\_distance\_to\_edge\_top

```gdscript
func tooltip_distance_to_edge_top(position: Vector2)
```

### tooltip\_distance\_to\_edge\_bottom

```gdscript
func tooltip_distance_to_edge_bottom(position: Vector2)
```

### tooltip\_distance\_to\_edge\_left

```gdscript
func tooltip_distance_to_edge_left(position: Vector2)
```

### tooltip\_distance\_to\_edge\_right

```gdscript
func tooltip_distance_to_edge_right(position: Vector2)
```

### clear

```gdscript
func clear()
```

