<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SchedEventCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`sched_event time object event`

Schedules the execution of an "event" found in "object" in a time in seconds.
If another event is running at the time, execution starts when the running
event ends.

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