<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# main.gd

**Extends:** [Node](../Node)

## Description

Escoria main room handling and scene switcher

## Property Descriptions

### last\_scene\_global\_id

```gdscript
var last_scene_global_id: String
```

Global id of the last scene the player was before current scene

### current\_scene

```gdscript
var current_scene: Node
```

Current scene room being displayed

### wait\_level

```gdscript
var wait_level
```

The Escoria context currently in wait state

### bg\_music

```gdscript
var bg_music
```

Reference to the ESCBackgroundMusic node

### scene\_transition

```gdscript
var scene_transition
```

Reference to the scene transition node

## Method Descriptions

### set\_scene

```gdscript
func set_scene(p_scene: Node) -> void
```

Set current scene

#### Parameters

- p_scene: Scene to set

### clear\_scene

```gdscript
func clear_scene() -> void
```

Cleanup the current scene

### set\_camera\_limits

```gdscript
func set_camera_limits(camera_limit_id: int = 0) -> void
```

Set the camera limits

#### Parameters

* camera_limits_id: The id of the room's camera limits to set

### save\_game

```gdscript
func save_game(p_savegame_res: Resource) -> void
```

### check\_game\_scene\_methods

```gdscript
func check_game_scene_methods()
```

Sanity check that the game.tscn scene's root node script MUST
implement the following methods. If they do not exist, stop immediately.
Implement them, even if empty

## Signals

- signal room_ready(): Signal sent when the room is loaded and ready.
