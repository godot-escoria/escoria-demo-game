<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SpawnCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`spawn path [object2]`

Instances a scene determined by "path", and places in the position of
object2 (object2 is optional)

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