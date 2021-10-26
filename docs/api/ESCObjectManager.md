<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCObjectManager

**Extends:** [Node](../Node)

## Description

A manager for ESC objects

## Constants Descriptions

### RESERVED\_OBJECTS

```gdscript
const RESERVED_OBJECTS: Array = ["_music","_sound","_speech","_camera"]
```

## Property Descriptions

### objects

```gdscript
var objects: Dictionary
```

The hash of registered objects (the global id is the key)

## Method Descriptions

### register\_object

```gdscript
func register_object(object: ESCObject, force: bool = false) -> void
```

Register the object in the manager

#### Parameters

- object: Object to register
- force: Register the object, even if it has already been registered

### has

```gdscript
func has(global_id: String) -> bool
```

Check wether an object was registered

#### Parameters

- global_id: Global ID of object
**Returns** Wether the object exists in the object registry

### get\_object

```gdscript
func get_object(global_id: String) -> ESCObject
```

Get the object from the object registry

#### Parameters

- global_id: The global id of the object to retrieve
**Returns** The retrieved object, or null if not found

### unregister\_object

```gdscript
func unregister_object(object: ESCObject) -> void
```

Remove an object from the registry

#### Parameters

- object: The object to unregister

### save\_game

```gdscript
func save_game(p_savegame: ESCSaveGame) -> void
```

Insert data to save into savegame.

#### Parameters

- p_savegame: The savegame resource

### get\_start\_location

```gdscript
func get_start_location() -> ESCLocation
```

