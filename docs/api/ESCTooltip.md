<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCTooltip

**Extends:** [RichTextLabel](../RichTextLabel)

## Description

A tooltip displaying <verb> <item1> [<item2>]

## Constants Descriptions

### MAX\_HEIGHT

```gdscript
const MAX_HEIGHT: int = 500
```

Maximum height of the label

### MAX\_WIDTH

```gdscript
const MAX_WIDTH: int = 200
```

Maximum width of the label

### MIN\_HEIGHT

```gdscript
const MIN_HEIGHT: int = 30
```

 Minimum height of the label

### ONE\_LINE\_HEIGHT

```gdscript
const ONE_LINE_HEIGHT: int = 16
```

Height of one line in the label

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

Color of the label

### offset\_from\_cursor

```gdscript
export var offset_from_cursor = "(10, 0)"
```

Vector2 defining the offset from the cursor

### debug\_mode

```gdscript
export var debug_mode = false
```

- **Setter**: `set_debug_mode`

Activates debug mode. If enabled, shows the label with a white background.

### debug\_texturerect\_node

```gdscript
var debug_texturerect_node: TextureRect
```

Node containing the debug white background

## Method Descriptions

### set\_color

```gdscript
func set_color(p_color: Color)
```

 Set the color of the label

## Parameters
 - p_color: the color to set the label

### set\_debug\_mode

```gdscript
func set_debug_mode(p_debug_mode: bool)
```

 Enable/disable debug mode of the label. If enabled, the label is displayed
with a white background.

## Parameters
- p_debug_mode: if true, enable debug mode. False to disable

### set\_target

```gdscript
func set_target(target: String, needs_second_target: bool = false) -> void
```

 Set the first target of the label.

## Parameters
- target: String the target to add to the label
- needs_second_target: if true, the label will prepare for a second target

### set\_target2

```gdscript
func set_target2(target2: String) -> void
```

 Set the second target of the label

## Parameters
- target2: String the second target to add to the label

### update\_tooltip\_text

```gdscript
func update_tooltip_text()
```

Update the tooltip text.

### update\_size

```gdscript
func update_size()
```

Update the tooltip size according to the text.

### tooltip\_distance\_to\_edge\_top

```gdscript
func tooltip_distance_to_edge_top(position: Vector2)
```

Return the tooltip distance to top edge.

## Parameters
- position: the position to test

**Return**
The distance to the edge.

### tooltip\_distance\_to\_edge\_bottom

```gdscript
func tooltip_distance_to_edge_bottom(position: Vector2)
```

Return the tooltip distance to bottom edge.

## Parameters
- position: the position to test

**Return**
The distance to the edge.

### tooltip\_distance\_to\_edge\_left

```gdscript
func tooltip_distance_to_edge_left(position: Vector2)
```

Return the tooltip distance to left edge.

## Parameters
- position: the position to test

**Return**
The distance to the edge.

### tooltip\_distance\_to\_edge\_right

```gdscript
func tooltip_distance_to_edge_right(position: Vector2)
```

Return the tooltip distance to right edge.

## Parameters
- position: the position to test

**Return**
The distance to the edge.

### clear

```gdscript
func clear()
```

Clear the tooltip targets texts