<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# QueueResourceCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`queue_resource path [front_of_queue]`

Queues the load of a resource in a background thread. The `path` must be a
full path inside your game, for example "res://scenes/next_scene.tscn". The
"front_of_queue" parameter is optional (default value false), to put the
resource in the front of the queue. Queued resources are cleared when a
change scene happens (but after the scene is loaded, meaning you can queue
resources that belong to the next scene).

@ESC

## Method Descriptions

### configure

```gdscript
func configure() -> ESCCommandArgumentDescriptor
```

Return the descriptor of the arguments of this command

### validate

```gdscript
func validate(arguments: Array) -> bool
```

Validate wether the given arguments match the command descriptor

### run

```gdscript
func run(command_params: Array) -> int
```

Run the command