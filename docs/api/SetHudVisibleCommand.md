<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SetHudVisibleCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`set_hud_visible visible`

If you have a cutscene like sequence where the player doesn't have control,
and you also have HUD elements visible, use this to hide the HUD. You want
to do that because it explicitly signals the player that there is no control
over the game at the moment. "visible" is true or false.

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