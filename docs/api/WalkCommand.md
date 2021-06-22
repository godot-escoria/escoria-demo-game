<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# WalkCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`walk object1 object2 [speed]`

Walks, using the walk animation, object1 towards the position of object2,
at the speed determined by object1's "speed" property,
unless overridden. This command is non-blocking.

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