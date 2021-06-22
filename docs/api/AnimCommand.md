<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# AnimCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`anim object name [reverse]`

Executes the animation specificed with the "name" parameter on the object,
without blocking. The next command in the event will be executed immediately
after. Optional parameters:

* reverse: plays the animation in reverse when true

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