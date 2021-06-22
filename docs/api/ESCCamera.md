<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCCamera

**Extends:** [Camera2D](../Camera2D)

## Description

Camera handling

## Property Descriptions

### tween

```gdscript
var tween
```

Reference to the tween node for animating camera movements

### target

```gdscript
var target: Vector2 = "(0, 0)"
```

Target position of the camera

### follow\_target

```gdscript
var follow_target: Node
```

The object to follow

### zoom\_target

```gdscript
var zoom_target: Vector2
```

Target zoom of the camera

### zoom\_time

```gdscript
var zoom_time
```

### zoom\_transform

```gdscript
var zoom_transform
```

This is needed to adjust dialog positions and such, see dialog_instance.gd

## Method Descriptions

### set\_limits

```gdscript
func set_limits(limits: ESCCameraLimits)
```

Sets camera limits so it doesn't go out of the scene

#### Parameters

- limits: The limits to set

### set\_drag\_margin\_enabled

```gdscript
func set_drag_margin_enabled(p_dm_h_enabled, p_dm_v_enabled)
```

### set\_target

```gdscript
func set_target(p_target, p_speed: float = 0)
```

### set\_camera\_zoom

```gdscript
func set_camera_zoom(p_zoom_level, p_time)
```

### push

```gdscript
func push(p_target, p_time, p_type)
```

### shift

```gdscript
func shift(p_x, p_y, p_time, p_type)
```

### target\_reached

```gdscript
func target_reached()
```

