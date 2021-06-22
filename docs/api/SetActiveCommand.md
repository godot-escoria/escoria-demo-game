<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# SetActiveCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`set_active object value`

Changes the "active" state of the object, value can be true or false.
Inactive objects are hidden in the scene.

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