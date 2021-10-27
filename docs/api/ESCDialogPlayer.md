<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCDialogPlayer

**Extends:** [Node](../Node)

## Description

Escoria dialog player

## Property Descriptions

### is\_speaking

```gdscript
var is_speaking: bool = false
```

Wether the player is currently speaking

## Method Descriptions

### say

```gdscript
func say(character: String, type: String, text: String) -> var
```

Make a character say a text

#### Parameters

- character: Character that is talking
- type: UI to use for the dialog
- text: Text to say

### speedup

```gdscript
func speedup() -> void
```

Called when a dialog line is skipped

### start\_dialog\_choices

```gdscript
func start_dialog_choices(dialog: ESCDialog, type: String = "simple")
```

Display a list of choices

#### Parameters

- dialog: The dialog to start

### interrupt

```gdscript
func interrupt()
```

Interrupt the currently running dialog

## Signals

- signal option_chosen(option): Emitted when an answer as chosem

##### Parameters

- option: The dialog option that was chosen
- signal say_finished(): Emitted when a say command finished
