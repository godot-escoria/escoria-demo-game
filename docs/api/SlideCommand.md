<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SlideCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`slide object1 object2 [speed]`

Moves object1 towards the position of object2, at the speed determined by
object1's "speed" property, unless overridden. This command is non-blocking.
It does not respect the room's navigation polygons, so you can move items
where the player can't walk.

@STUB
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