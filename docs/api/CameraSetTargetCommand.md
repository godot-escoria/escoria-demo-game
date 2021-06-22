<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# CameraSetTargetCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`camera_set_target speed object`

Configures the camera to set the target to the given `object`using `speed`
as speed limit.
This is the default behavior (default follow object is "player").

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