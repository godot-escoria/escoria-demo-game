<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# PlaySndCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`play_snd file [player]`

Plays the sound specificed with the "file" parameter on the sound player
`player`, without blocking. (player defaults to bg_sound)

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