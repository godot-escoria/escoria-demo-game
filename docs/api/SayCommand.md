<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SayCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`say object text [type] [avatar]`

Runs the specified string as a dialog said by the object. Blocks execution
until the dialog finishes playing. Optional parameters:

* "type" determines the type of dialog UI to use. Default value is "default"
* "avatar" determines the avatar to use for the dialog. Default value is
  "default"

@ESC

## Method Descriptions

### configure

```gdscript
func configure() -> ESCCommandArgumentDescriptor
```

Return the descriptor of the arguments of this command

### run

```gdscript
func run(command_params: Array) -> var
```

Run the command