<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# CustomCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`custom object node func_name [params]`

Calls the function `func_name` of the node `node` of object `object` with
the optional `params`. This is a blocking function

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