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

### room\_terrain

```gdscript
var room_terrain
```

Terrain of the current room

### dialog\_player

```gdscript
var dialog_player: ESCDialogPlayer
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

### controller

```gdscript
var controller: ESCController
```

The controller in charge of converting an action verb on a game object
into an actual action

### game\_scene

```gdscript
var game_scene: ESCGame
```

 The game scene loaded

### start\_script

```gdscript
var start_script: ESCScript
```

The compiled start script loaded from ProjectSettings
escoria/main/game_start_script

## Method Descriptions

### init

```gdscript
func init()
```

Called by Escoria's main_scene as very very first event EVER.
Usually you'll want to show some logos animations before spawning the main
menu in the escoria/main/game_start_script 's :init event

### new\_game

```gdscript
func new_game()
```

Called by Main menu "start new game"

### do

```gdscript
func do(action: String, params: Array, can_interrupt: bool = false) -> void
```

Run a generic action

#### Parameters

- action: type of the action to run
- params: Parameters for the action
- can_interrupt: if true, this command will interrupt any ongoing event
before it is finished

### set\_game\_paused

```gdscript
func set_game_paused(p_paused: bool)
```

Pauses or unpause the game

#### Parameters
- p_paused: if true, pauses the game. If false, unpauses the game.

### run\_event\_from\_script

```gdscript
func run_event_from_script(script: ESCScript, event_name: String)
```

Runs the event "event_name" from the "script" ESC script.

#### Parameters
- script: ESC script containing the event to run. The script must have been
loaded.
- event_name: Name of the event to run

## Signals

- signal request_pause_menu(): Signal sent when pause menu has to be displayed
