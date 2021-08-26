<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCDialogsPlayer

**Extends:** [ResourcePreloader](../ResourcePreloader)

## Description

Escoria dialog player

## Property Descriptions

### is\_speaking

```gdscript
var is_speaking
```

Wether the player is currently speaking

## Method Descriptions

### say

```gdscript
func say(character: String, ui: String, line: String) -> var
```

A short one line dialog

#### Parameters

- character: Character that is talking
- ui: UI to use for the dialog
- line: Line to say

### finish\_fast

```gdscript
func finish_fast() -> void
```

Called when a dialog line is skipped

### start\_dialog\_choices

```gdscript
func start_dialog_choices(dialog: ESCDialog)
```

Display a list of choices

#### Parameters

- dialog: The dialog to start

### play\_dialog\_option\_chosen

```gdscript
func play_dialog_option_chosen(option: ESCDialogOption)
```

Called when an option was chosen and emits the option_chosen signal

#### Parameters

- option: Option, that was chosen.

## Signals

- signal option_chosen(option): Emitted when an answer as chosem

##### Parameters

- option: The dialog option that was chosen
- signal dialog_line_finished(): Emitted when a dialog line was finished
