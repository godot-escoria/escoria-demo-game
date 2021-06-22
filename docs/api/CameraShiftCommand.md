<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# CameraShiftCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`camera_shift x y [time] [type]`

Shift camera by `x` and `y` pixels over `time` seconds. `type` is any of the
Tween.TransitionType values without the prefix, eg. LINEAR, QUART or CIRC;
defaults to QUART.

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