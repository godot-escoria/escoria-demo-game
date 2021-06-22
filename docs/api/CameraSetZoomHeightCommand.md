<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# CameraSetZoomHeightCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`camera_set_zoom_height pixels [time]

Zooms the camera in/out to the desired `pixels` height.
An optional `time` in seconds controls how long it takes for the camera
to zoom into position.

@ESC

## Method Descriptions

### configure

```gdscript
func configure() -> ESCCommandArgumentDescriptor
```

Return the descriptor of the arguments of this command

### validate

```gdscript
func validate(arguments: Array)
```

Validate wether the given arguments match the command descriptor

### run

```gdscript
func run(command_params: Array) -> int
```

Run the command