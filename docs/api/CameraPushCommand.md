<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# CameraPushCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`camera_push target [time] [type]`

Push camera to `target`. Target must have camera_pos set. If it's of type
Camera2D, its zoom will be used as well as position. `type` is any of the
Tween.TransitionType values without the prefix, eg. LINEAR, QUART or CIRC;
defaults to QUART. A `time` value of 0 will set the camera immediately.

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