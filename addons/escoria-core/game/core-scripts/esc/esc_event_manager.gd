# A manager for running events
extends Node
class_name ESCEventManager


# Emitted when the event did finish running
signal event_finished(event_name, return_code)


# A queue of events to run
var events_queue: Array = []

# A list of currently scheduled events
var scheduled_events: Array = []


# Handle the events queue and scheduled events
func _process(delta: float) -> void:
	if events_queue.size() > 0:
		var running_event = events_queue.pop_front()
		if not running_event.is_connected(
			"finished", self, "_on_event_finished"
		):
			running_event.connect(
				"finished", 
				self, 
				"_on_event_finished",
				[running_event]
			)
		running_event.run()
	for event in self.scheduled_events:
		(event as ESCScheduledEvent).timeout -= delta
		if (event as ESCScheduledEvent).timeout <= 0:
			self.scheduled_events.erase(event)
			self.events_queue.append(event)


# Queue a new event to run
func queue_event(event: ESCEvent) -> void:
	events_queue.append(event)


# Schedule an event to run after a timeout
func schedule_event(event: ESCEvent, timeout: float) -> void:
	scheduled_events.append(ESCScheduledEvent.new(event, timeout))


# The event finished running
func _on_event_finished(return_code: int, event: ESCEvent) -> void:
	escoria.logger.debug(
		"Event %s ended with return code %d" % [event.name, return_code]
	)
	event.disconnect("finished", self, "_on_event_finished")
	match(return_code):
		ESCExecution.RC_CANCEL:
			self.scheduled_events = []
			self.events_queue = []
			return_code = ESCExecution.RC_OK
	emit_signal("event_finished", return_code, event.name)
