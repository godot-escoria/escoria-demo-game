<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCSoundPlayer

**Extends:** [Control](../Control)

## Description

Background sound player

## Property Descriptions

### global\_id

```gdscript
export var global_id: String = "_sound"
```

Global id of the background sound player

### state

```gdscript
var state: String = "default"
```

The state of the sound player. "default" or "off" disable sound
Any other state refers to a sound stream that should be played

### stream

```gdscript
var stream: AudioStreamPlayer
```

Reference to the audio player

## Method Descriptions

### set\_state

```gdscript
func set_state(p_state: String, p_force: bool = false)
```

Set the state of this player

#### Parameters

- p_state: New state to use
- p_force: Override the existing state even if the stream is still playing