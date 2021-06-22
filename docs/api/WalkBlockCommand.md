<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# WalkBlockCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`walk_block object1 object2 [speed]`

Walks, using the walk animation, object1 towards the position of object2,
at the speed determined by object1's "speed" property,
unless overridden. This command is blocking.

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
func run(command_params: Array) -> var
```

Run the command