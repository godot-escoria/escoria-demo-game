# A manager for running events
extends Node
class_name ESCEventManager

# Emitted when the event started execution
signal event_started(event_name)

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

# Whether the event manager is allowed to proceed with next event.
var can_process_next_event = true


func _ready():
	self.pause_mode = Node.PAUSE_MODE_STOP
	

# Handle the events queue and scheduled events
func _process(delta: float) -> void:
	if events_queue.size() > 0 and can_process_next_event:
		can_process_next_event = false
		_running_event = events_queue.pop_front()
		escoria.logger.debug(
			"esc_event_manager",
			[
				"Popping event %s from event_queue" \
				% _running_event.name if _running_event.get("name") != null \
				else str(_running_event)
			]
		)
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
		
		emit_signal("event_started", _running_event.name)
		_running_event.run()
	for event in self.scheduled_events:
		(event as ESCScheduledEvent).timeout -= delta
		if (event as ESCScheduledEvent).timeout <= 0:
			self.scheduled_events.erase(event)
			self.events_queue.append(event.event)


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
	can_process_next_event = true
	match(return_code):
		ESCExecution.RC_CANCEL:
			return_code = ESCExecution.RC_OK
	emit_signal("event_finished", return_code, event.name)


# Interrupt the event currently running.
func interrupt_running_event():
	if _running_event == null:
		return
	_running_event.interrupt()

# Clears the event queue.
func clear_event_queue():
	events_queue.clear()
