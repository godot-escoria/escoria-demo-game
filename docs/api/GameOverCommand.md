<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# GameOverCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`game_over continue_enabled show_credits`

Ends the game. Use the "continue_enabled" parameter to enable or disable the
continue button in the main menu afterwards. The "show_credits" parameter
loads the ui/end_credits scene if true. You can configure it to your regular
credits scene if you want.

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