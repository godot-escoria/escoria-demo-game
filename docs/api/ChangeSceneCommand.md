<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ChangeSceneCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`change_scene path [disable_automatic_transition] [run_events]`

Loads a new scene, specified by "path".
 The `disable_automatic_transition` is a boolean (default false) can be set
to true to disable automatic transitions between scenes, to allow you
to control your transitions manually using the `transition` command.
The `run_events` variable is a boolean (default true) which you never want
to set manually! It's there only to benefit save games, so they don't
conflict with the scene's events.

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
func run(command_params: Array) -> var
```

Run the command