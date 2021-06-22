<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SetGlobalsCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`set_globals pattern value`

Changes the value of multiple globals using a wildcard pattern, where "*"
matches zero or more arbitrary characters and "?" matches any single
character except a period (".").

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