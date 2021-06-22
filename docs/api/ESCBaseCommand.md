<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCBaseCommand

**Extends:** [Node](../Node)

## Description

A base class for every ESC command.
Extending classes have to override the configure and run function

## Method Descriptions

### configure

```gdscript
func configure() -> ESCCommandArgumentDescriptor
```

Return the descriptor of the arguments of this command

### validate

```gdscript
func validate(arguments: Array) -> bool
```

Validate wether the given arguments match the command descriptor

### run

```gdscript
func run(command_params: Array) -> int
```

Run the command