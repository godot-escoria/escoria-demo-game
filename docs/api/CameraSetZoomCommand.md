<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# CameraSetZoomCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`camera_set_zoom magnitude [time]`

Zooms the camera in/out to the desired `magnitude`. Values larger than 1 zooms
the camera out, and smaller values zooms in, relative to the default value
of 1. An optional `time` in seconds controls how long it takes for the camera
to zoom into position.

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