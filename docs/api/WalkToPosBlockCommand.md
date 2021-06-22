<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# WalkToPosBlockCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`walk_to_pos_block player x y`

Makes the `player` walk to the position `x`/`y`. This is a blocking command.

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