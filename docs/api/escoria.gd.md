<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# escoria.gd

**Extends:** [Node](../Node)

## Description

The escorie main script

## Enumerations

### GAME\_STATE

```gdscript
const GAME_STATE: Dictionary = {"DEFAULT":0,"DIALOG":1,"WAIT":2}
```

An enum of game states
* DEFAULT - Default mode
* DIALOG - Game is running a dialog
* WAIT - Game is currently waiting for a specified time

## Property Descriptions

### main\_menu\_instance

```gdscript
var main_menu_instance
```

The instance of the used main menu scene

### dialog\_player

```gdscript
var dialog_player
```

Dialog player instantiator. This instance is called directly for dialogs.

### inventory

```gdscript
var inventory
```

The inventory scene used

### room\_terrain

```gdscript
var room_terrain
```

The terrain of the current main room

### esc\_compiler

```gdscript
var esc_compiler
```

The ESC compiler instance

### logger

```gdscript
var logger
```

The logger instance

### main

```gdscript
var main
```

The main scene

### esc\_runner

```gdscript
var esc_runner
```

The ESC main loop

### esc\_level\_runner

```gdscript
var esc_level_runner
```

The ESC interpreter

### inputs\_manager

```gdscript
var inputs_manager
```

The escoria inputs manager

### utils

```gdscript
var utils
```

Several utilities

### current\_state

```gdscript
var current_state
```

The current state of the game

### game\_size

```gdscript
var game_size
```

The game resolution

## Method Descriptions

### new\_game

```gdscript
func new_game()
```

Called by Main menu "start new game"

### register\_object

```gdscript
func register_object(object: Object)
```

Register an object to the matching manager. (A dialog player as the
main dialog player, an item in the ESC runner, etc.)

#### Parameters

- object: The object to register

### do

```gdscript
func do(action: String, params: Array) -> void
```

Run a generic action

#### Parameters

- action: type of the action to run
- params: Parameters for the action