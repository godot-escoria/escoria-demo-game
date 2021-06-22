<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCPlayer

**Extends:** [ESCItem](../ESCItem) < [Area2D](../Area2D)

## Description

A playable character
TODO
- Currently the sprite node needs to be named "sprite". This is bad.
- Animation management doesn't allow using AnimationPlayer yet. Need to find
 the best solution to manage both AnimatedSprite and AnimationPlayer.

## Property Descriptions

### camera\_position\_node

```gdscript
export var camera_position_node = ""
```

The node that references the camera position

## Method Descriptions

### get\_camera\_pos

```gdscript
func get_camera_pos()
```

Return the camera position if a camera_position_node exists or the
global position of the player