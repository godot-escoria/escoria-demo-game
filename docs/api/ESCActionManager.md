<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCActionManager

**Extends:** [Object](../Object)

## Description

Manages currently carried out actions

## Property Descriptions

### current\_action

```gdscript
var current_action: String = ""
```

- **Setter**: `set_current_action`

Current verb used

### current\_tool

```gdscript
var current_tool: ESCObject
```

Current tool (ESCItem/ESCInventoryItem) used

## Method Descriptions

### set\_current\_action

```gdscript
func set_current_action(action: String)
```

Set the current action

### clear\_current\_action

```gdscript
func clear_current_action()
```

Clear the current action

### clear\_current\_tool

```gdscript
func clear_current_tool()
```

Clear the current tool

### activate

```gdscript
func activate(action: String, target: ESCObject, combine_with: ESCObject = null) -> var
```

## Signals

- signal action_changed(): The current action was changed
- signal action_finished(): Emitted, when an action has been completed
