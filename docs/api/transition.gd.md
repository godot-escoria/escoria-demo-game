<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# transition.gd

**Extends:** [ColorRect](../ColorRect)

## Description

A transition player for scene changes

## Property Descriptions

### transition\_name

```gdscript
export var transition_name: String = ""
```

## Method Descriptions

### transition\_out

```gdscript
func transition_out(p_transition_name: String = "") -> var
```

Transition out

## Parameters

- p_transition_name: name of the transition to play (if empty string, uses
the default transition)

### transition\_in

```gdscript
func transition_in(p_transition_name: String = "") -> var
```

Transition in

## Parameters

- p_transition_name: name of the transition to play (if empty string, uses
the default transition)

### has\_transition

```gdscript
func has_transition(p_name: String) -> bool
```

Returns true whether the transition scene has a transition corresponding
to name provided.

## Parameters

- p_name: The name of the transition to test

*Returns* true if a transition exists with given name.

## Signals

- signal transition_done(): Emitted when the transition was played
