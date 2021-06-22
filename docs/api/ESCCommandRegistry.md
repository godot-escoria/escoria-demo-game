<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCCommandRegistry

**Extends:** [Object](../Object)

## Description

A registry of ESC command objects

## Property Descriptions

### registry

```gdscript
var registry: Dictionary
```

The registry of registered commands

## Method Descriptions

### load\_command

```gdscript
func load_command(command_name: String) -> ESCBaseCommand
```

Load a command by its name

#### Parameters

- command_name: Name of command to load
**Returns** The command object

### get\_command

```gdscript
func get_command(command_name: String) -> ESCBaseCommand
```

Retrieve a command from the command registry

#### Parameters

- command_name: The name of the command
**Returns** The command object