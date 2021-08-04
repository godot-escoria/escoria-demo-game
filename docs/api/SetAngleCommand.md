<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SetAngleCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`set_angle object degrees [immediate]`

Turns object to a degrees angle without animations. 0 sets object facing
forward, 90 sets it 90 degrees clockwise ("east") etc. When turning to the
destination angle, animations are played if they're defined in animations.

object must be player or interactive. degrees must be between [0, 360] or an
error is reported.

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