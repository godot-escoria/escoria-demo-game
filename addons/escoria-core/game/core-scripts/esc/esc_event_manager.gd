# A manager for running events
extends Node
class_name ESCEventManager


# Emitted when the event did finish running
signal event_finished(event_name, return_code)

# Emitted when the event was interrupted
signal event_interrupted(event_name, return_code)


# A queue of events to run
var events_queue: Array = []

# A list of currently scheduled events
var scheduled_events: Array = []

# Currently running event
var _running_event: ESCEvent


func _ready():
	self.pause_mode = Node.PAUSE_MODE_STOP
	

# Handle the events queue and scheduled events
func _process(delta: float) -> void:
	if events_queue.size() > 0:
		_running_event = events_queue.pop_front()
		if not _running_event.is_connected(
			"finished", self, "_on_event_finished"
		):
			_running_event.connect(
				"finished", 
				self, 
				"_on_event_finished",
				[_running_event]
			)
		if not _running_event.is_connected(
			"interrupted", self, "_on_event_finished"
		):
			_running_event.connect(
				"interrupted", 
				self, 
				"_on_event_finished",
				[_running_event]
			)
		
		_running_event.run()
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
	event.disconnect("interrupted", self, "_on_event_finished")
	_running_event = null
	match(return_code):
		ESCExecution.RC_CANCEL:
			self.scheduled_events = []
			self.events_queue = []
			return_code = ESCExecution.RC_OK
	emit_signal("event_finished", return_code, event.name)


# Interrupt the event currently running.
func interrupt_running_event():
	if _running_event == null:
		return
	_running_event.interrupt()
