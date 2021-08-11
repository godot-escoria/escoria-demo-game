<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# escoria.gd

**Extends:** [Node](../Node)

## Description

The escoria main script

## Enumerations

### GAME\_STATE

```gdscript
const GAME_STATE: Dictionary = {"DEFAULT":0,"DIALOG":1,"WAIT":2}
```

Current game state
* DEFAULT: Common game function
* DIALOG: Game is playing a dialog
* WAIT: Game is waiting

## Constants Descriptions

### ESCORIA\_VERSION

```gdscript
const ESCORIA_VERSION: String = "0.1.0"
```

Escoria version number

## Property Descriptions

### logger

```gdscript
var logger: ESCLogger
```

Logger used

### utils

```gdscript
var utils: ESCUtils
```

Several utilities

### inventory\_manager

```gdscript
var inventory_manager: ESCInventoryManager
```

The inventory manager instance

### action\_manager

```gdscript
var action_manager: ESCActionManager
```

The action manager instance

### esc\_compiler

```gdscript
var esc_compiler: ESCCompiler
```

ESC compiler instance

### event\_manager

```gdscript
var event_manager: ESCEventManager
```

ESC Event manager instance

### globals\_manager

```gdscript
var globals_manager: ESCGlobalsManager
```

ESC globals registry instance

### object\_manager

```gdscript
var object_manager: ESCObjectManager
```

ESC object manager instance

### command\_registry

```gdscript
var command_registry: ESCCommandRegistry
```

ESC command registry instance

### resource\_cache

```gdscript
var resource_cache: ESCResourceCache
```

Resource cache handler

### main\_menu\_instance

```gdscript
var main_menu_instance
```

Instance of the main menu

### room\_terrain

```gdscript
var room_terrain
```

Terrain of the current room

### dialog\_player

```gdscript
var dialog_player: ESCDialogsPlayer
```

Dialog player instantiator. This instance is called directly for dialogs.

### inventory

```gdscript
var inventory
```

Inventory scene

### settings

```gdscript
var settings: ESCSaveSettings
```

These are settings that the player can affect and save/load later

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

### main

```gdscript
var main
```

The main scene

### inputs\_manager

```gdscript
var inputs_manager: ESCInputsManager
```

The escoria inputs manager

### save\_manager

```gdscript
var save_manager: ESCSaveManager
```

Savegames and settings manager

## Method Descriptions

### new\_game

```gdscript
func new_game()
```

Called by Main menu "start new game"

### do

```gdscript
func do(action: String, params: Array) -> void
```

Run a generic action

#### Parameters

- action: type of the action to run
- params: Parameters for the action

### set\_game\_paused

```gdscript
func set_game_paused()
```

### set\_game\_unpaused

```gdscript
func set_game_unpaused()
```

