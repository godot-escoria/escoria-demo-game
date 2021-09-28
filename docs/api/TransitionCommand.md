<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# TransitionCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`transition transition_name in|out [delay]`

Performs a transition in our out manually.

Parameters:
- transition_name: Name of the transition shader from one of the transition
  directories
- in|out: Wether to play the transition in IN- or OUT-mode
- delay: Delay for the transition to take. Defaults to 1 second

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
func run(command_params: Array) -> var
```

Run the command