<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCSaveManager

## Constants Descriptions

### SAVE\_NAME\_TEMPLATE

```gdscript
const SAVE_NAME_TEMPLATE: String = "save_%03d.tres"
```

Template for savegames filenames

### SETTINGS\_TEMPLATE

```gdscript
const SETTINGS_TEMPLATE: String = "settings.tres"
```

Template for settings filename

## Property Descriptions

### save\_enabled

```gdscript
var save_enabled: bool = true
```

If true, saving a game is enabled. Else, saving is disabled

### save\_folder

```gdscript
var save_folder: String
```

Variable containing the saves folder obtained from Project Settings

### settings\_folder

```gdscript
var settings_folder: String
```

Variable containing the settings folder obtained from Project Settings

## Method Descriptions

### get\_saves\_list

```gdscript
func get_saves_list() -> Dictionary
```

Return a list of savegames metadata (id, date, name and game version)

### save\_game\_exists

```gdscript
func save_game_exists(id: int) -> bool
```

Returns true whether the savegame identified by id does exist

## Parameters
- id: integer suffix of the savegame file

### save\_game

```gdscript
func save_game(id: int, p_savename: String)
```

Save the current state of the game in a file suffixed with the id value.
This id can help with slots development for the game developer.

 ## Parameters
- id: integer suffix of the savegame file
- p_savename: name of the savegame

### load\_game

```gdscript
func load_game(id: int)
```

Load a savegame file from its id.

 ## Parameters
- id: integer suffix of the savegame file

### save\_settings

```gdscript
func save_settings()
```

Save the game settings in the settings file.

### load\_settings

```gdscript
func load_settings() -> Resource
```

Load the game settings from the settings file
**Returns** The Resource structure loaded from settings file