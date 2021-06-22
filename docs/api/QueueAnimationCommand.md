<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# QueueAnimationCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`queue_animation object animation`

Similar to queue_resource, queues the resources necessary to have an
animation loaded on an item. The resource paths are taken from the item
placeholders.

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