<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SayCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`say player text [type]`

Runs the specified string as a dialog said by the player. Blocks execution
until the dialog finishes playing.

The text supports translation keys by prepending the key and separating
it with a `:` from the text.

Example: `say player ROOM1_PICTURE:"Picture's looking good."`

Optional parameters:

* "type" determines the type of dialog UI to use. Default value is "default"

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
func run(command_params: Array) -> var
```

Run the command