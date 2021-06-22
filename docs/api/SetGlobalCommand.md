<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SetGlobalCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`set_global name value`

Changes the value of the global "name" with the value. Value can be "true",
"false" or an integer.

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