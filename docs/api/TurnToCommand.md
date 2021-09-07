<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# TurnToCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`turn_to object degrees [immediate]`

Turns object to a degrees angle with a directions animation.

0 sets object facing forward, 90 sets it 90 degrees clockwise ("east") etc.
When turning to the destination angle, animations are played if they're
defined in animations. object must be player or interactive. degrees must
be between [0, 360] or an error is reported.

Set immediate to true to show directly switch to the direction and not
show intermediate angles

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