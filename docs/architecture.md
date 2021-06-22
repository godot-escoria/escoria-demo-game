# Escoria architecture

## The plugin script, autoload and classes

According to the [concept of Godot plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/making_plugins.html), `Escoria`initializes itself in the plugin script [`addons/escoria-core/plugin.gd`](api/plugin.gd.md). This script is mostly used to initialize the [Escoria configuration items](configuration.md) and initialize (and later remove) the autoload scene [`escoria`](api/escoria.gd.md).

This scene binds together all required objects and interfaces in a central place.

In addition to this, various classes are defined in the respective class files and build up the various resources used in Escoria. See the [API-docs folder](api) for details.

## Nodes and objects of the Escoria autoload scene

The [Escoria autoload scene](api/escoria.gd.md) holds various nodes that provide vital parts of the engine.

### Logger

The [ESC logging framework](api/ESCLogger.md) is responsible to log various game events throughout the engine.

### Utils

Some smaller [utilities](api/ESCUtils.md) used on various places in the engine.

### Inventory manager

The [inventory manager](api/ESCInventoryManager.md) is responsible for storing inventory items the player carries around.

### Action Manager

The [action manager](api/ESCActionManager.md) is used when the player triggers a verb or uses items.

### ESC Compiler

The [ESC compiler](api/ESCCompiler.md) compiles files in the [ESC language](esc.md) into a list of events that can be run by the [ESC event manager](api/ESCEventManager.md).

### Event manager

The [ESC event manager](api/ESCEventManager.md) is used for queuing and scheduling events and handles the event execution.

### Globals manager

The [globals manager](api/ESCGlobalsManager.md) stores and handles global flags as described in the [ESC reference](esc.md#global_flags).

### Object manager

The [object manager](api/ESCObjectManager.md) handles the state of the objects used in the game (active/interactive/states). All objects, that should be handled by the engine and especially by ESC scripts are required to register to the object manager and have a unique global id.

### Command registry

The [command registry](api/ESCCommandRegistry.md) stores references to available ESC commands. By adding additional command directories via the settings, developers can enrich the ESC language just for their games.

### Resource cache

To optimize performance on platforms that support a larger memory footprint, resource can be cached in the [resource cache](api/ESCResourceCache.md) using the [`queue_resource`](esc.md#QueueResourceCommand.md) ESC command.

### Dialog player

The [dialog player](ESCDialogsPlayer.md) is used for handling dialogs and the [`say`](esc.md#SayCommand.md) command.

### Main

[`escoria.main`](api/main.gd.md) is the main scene manager used in Escoria that allows for switching scenes with transitions

### Inputs Manager

The [inputs manager](api/inputs_manager.gd.md) is the central component in Escoria to receive, handle and deliver input events.

### Save data

The [save data](api/save_data.gd.md) node is responsible for storing and loading savegames and the game settings.

## The Godot main scene of Escoria

The scene, that Godot loads when starting a game (the [*main scene*](https://docs.godotengine.org/en/stable/getting_started/step_by_step/exporting.html#setting-a-main-scene)) is set to [`addons/escoria-core/game/main_scene.tscn`](api/main_scene.gd.md) and basically instantiates the configured main menu scene and starts it.

## The interactivity workflow of Escoria

When the player clicks on an [`ESCItem`](api/ESCItem.md), the input manager is used to check and distribute the click to the currently running game interface. The game interface is then responsible for taking the respective action based on its workflow. This way, different user interfaces can be implemented. For a coin interface, for example, a right click would open the coin and let the player select the respective verb.

The game interface will ultimatively call `escoria.do`, which is a plumbing method, that handles core functions like walking, clicking on items or visiting areas. This method will then take care of the different actions, for example moving the player to the object (or its `interact_position`) and then running the appropriate event. The event is based on the `current_action` set in the [`actions manager`](api/ESCActionManager.md) (the verb) and the `current_tool` (the selected item). If the current verb is `use` and the event has an event `:use`, the [`event manager`](api/ESCEventManager.md) will run that specific event.