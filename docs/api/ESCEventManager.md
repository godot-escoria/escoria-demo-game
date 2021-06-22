<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCEventManager

**Extends:** [Node](../Node)

## Description

A manager for running events

## Property Descriptions

### events\_queue

```gdscript
var events_queue: Array
```

A queue of events to run

### scheduled\_events

```gdscript
var scheduled_events: Array
```

A list of currently scheduled events

## Method Descriptions

### queue\_event

```gdscript
func queue_event(event: ESCEvent) -> void
```

Queue a new event to run

### schedule\_event

```gdscript
func schedule_event(event: ESCEvent, timeout: float) -> void
```

Schedule an event to run after a timeout

## Signals

- signal event_finished(event_name, return_code): Emitted when the event did finish running
