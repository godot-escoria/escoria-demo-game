<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# PlaySndCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`play_snd object file [loop]`

Plays the sound specificed with the "file" parameter on the object, without
blocking. You can play background sounds, eg. during scene changes, with
`play_snd bg_snd res://...`

@STUB
@ESC

## Method Descriptions

### configure

```gdscript
func configure() -> ESCCommandArgumentDescriptor
```

Return the descriptor of the arguments of this command

### run

```gdscript
func run(command_params: Array) -> int
```

Run the command