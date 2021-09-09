<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# TurnToCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`turn_to object object_to_face [immediate]`

Turns object to face another object.

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