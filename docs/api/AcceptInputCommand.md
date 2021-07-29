<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# AcceptInputCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`accept_input [ALL|NONE|SKIP]`

What type of input does the game accept. ALL is the default, SKIP allows
skipping of dialog but nothing else, NONE denies all input. Including opening
the menu etc. SKIP and NONE also disable autosaves.

*Note* that SKIP gets reset to ALL when the event is done, but NONE persists.
This allows you to create cut scenes with SKIP where the dialog can be
skipped, but also initiate locked#### down cutscenes with accept_input
NONE in :setup and accept_input ALL later in :ready.

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