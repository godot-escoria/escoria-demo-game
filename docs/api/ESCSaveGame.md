<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCSaveGame

**Extends:** [Resource](../Resource)

## Description

Resource used for holding savegames data.

## Constants Descriptions

### MAIN\_CURRENT\_SCENE\_FILENAME\_KEY

```gdscript
const MAIN_CURRENT_SCENE_FILENAME_KEY: String = "current_scene_filename"
```

Access key for the main data current_scene_filename

### MAIN\_LAST\_SCENE\_GLOBAL\_ID\_KEY

```gdscript
const MAIN_LAST_SCENE_GLOBAL_ID_KEY: String = "last_scene_global_id"
```

Access key for the main data last_scene_global_id

## Property Descriptions

### escoria\_version

```gdscript
export var escoria_version: String = ""
```

Escoria version which the savegame was created with.

### game\_version

```gdscript
export var game_version: String = ""
```

Game version which the savegame was created with.

### name

```gdscript
export var name: String = ""
```

 Name of the savegame. Can be custom value, provided by the player.

### date

```gdscript
export var date: String = ""
```

 Date of creation of the savegame.

### main

```gdscript
export var main: Dictionary = {}
```

 Main data to be saved

### globals

```gdscript
export var globals: Dictionary = {}
```

Escoria Global variables exported from ESCGlobalsManager

### objects

```gdscript
export var objects: Dictionary = {}
```

Escoria objects exported from ESCObjectsManager