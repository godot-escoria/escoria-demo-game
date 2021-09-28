<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCTransitionPlayer

**Extends:** [ColorRect](../ColorRect)

## Description

A transition player for scene changes

## Enumerations

### TRANSITION\_MODE

```gdscript
const TRANSITION_MODE: Dictionary = {"IN":0,"OUT":1}
```

The valid transition modes

## Method Descriptions

### transition

```gdscript
func transition(transition_name: String = "", mode: int, duration: float = 1) -> void
```

### get\_transition

```gdscript
func get_transition(name: String) -> String
```

Returns the full path for a transition shader based on its name

## Parameters

- name: The name of the transition to test

*Returns* the full path to the shader or an empty string, if it can't be found

### has\_transition

```gdscript
func has_transition(name: String) -> bool
```

Returns true whether the transition scene has a transition corresponding
to name provided.

## Parameters

- name: The name of the transition to test

*Returns* true if a transition exists with given name.

## Signals

- signal transition_done(): Emitted when the transition was played
