<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# CameraSetPosCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`camera_set_pos speed x y`

Moves the camera to a position defined by "x" and "y", at the speed defined
by "speed" in pixels per second. If speed is 0, camera is teleported to the
position.

@ESC

## Method Descriptions

### configure

```gdscript
func configure() -> ESCCommandArgumentDescriptor
```

Return the descriptor of the arguments of this command

### run

```gdscript
func run(command_params: Array) -> int
```

Run the command