<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SetSoundStateCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`set_sound_state player sound loop`

Change the sound playing on `player` to `sound` with optional looping if
`loop` is true.
Valid players are "_music" and "_sound".
Aside from paths to sound or music files, the values *off* and *default*.
*default* is the default value.
are also valid for `sound`

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