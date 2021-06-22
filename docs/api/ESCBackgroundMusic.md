<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCBackgroundMusic

**Extends:** [Control](../Control)

## Description

Background music player

## Property Descriptions

### global\_id

```gdscript
export var global_id: String = "bg_music"
```

Global id of the background music player

### state

```gdscript
var state: String = "default"
```

The state of the music player. "default" or "off" disable music
Any other state refers to a music stream that should be played

### stream

```gdscript
var stream: AudioStreamPlayer
```

Reference to the audio player

## Method Descriptions

### set\_state

```gdscript
func set_state(p_state: String, p_force: bool = false) -> void
```

Set the state of this player

#### Parameters

- p_state: New state to use
- p_force: Override the existing state even if the stream is still playing