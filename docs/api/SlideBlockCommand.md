<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SlideBlockCommand

**Extends:** [SlideCommand](../SlideCommand) < [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`slide_block object1 object2 [speed]`

Moves object1 towards the position of object2, at the speed determined by
object1's "speed" property, unless overridden. This command is blocking.
It does not respect the room's navigation polygons, so you can move items
where the player can't walk.

@ESC

## Method Descriptions

### run

```gdscript
func run(command_params: Array) -> var
```

Run the command