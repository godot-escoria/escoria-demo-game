<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SetStateCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`set_state object state [immediate]`

Changes the state of an object, and executes the state animation if present.
The command can be used to change the appearance of an item or a player
character.
If `immediate` is set to true, the animation is run directly

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