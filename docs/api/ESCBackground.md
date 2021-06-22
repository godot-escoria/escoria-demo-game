<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCBackground

**Extends:** [TextureRect](../TextureRect)

## Description

ESCBackground's purpose is to display a background image and receive input
events on the background. More precisely, the TextureRect under ESCBackground
does not receive events itself - if it did, it would also eat all events like
hotspot focusing and such. Instead, we set the TextureRect mouse filter to
MOUSE_FILTER_IGNORE, and we use an Area2D node to receive the input events.

If ESCBackground doesn't contain a texture, it is important that its rect_size
is set over the whole scene, because its rect_size is then used to create the
Area2D node under it. If the rect_size is wrongly set, the background may
receive no input.

## Property Descriptions

### esc\_script

```gdscript
export var esc_script = ""
```

The ESC script connected to this background

## Method Descriptions

### manage\_input

```gdscript
func manage_input(_viewport, event, _shape_idx) -> void
```

Manage inputs reaching the Area2D and emit the events to the input manager
TODO: Don't change private variables here, use an event for BUTTON_WHEEL

#### Parameters
- _viewport: (not used)
- event: Event received
- _shape_idx: (not used)

### get\_full\_area\_rect2

```gdscript
func get_full_area_rect2() -> Rect2
```

Calculate the actual area taken by this background depending on its
Texture or set size
**Returns** The correct area size

## Signals

- signal double_left_click_on_bg(position): The background was double clicked

#### Parameters

- position: The position where the player clicked
- signal left_click_on_bg(position): The background was left clicked

#### Parameters

- position: The position where the player clicked
- signal right_click_on_bg(position): The background was right clicked

#### Parameters

- position: The position where the player clicked
