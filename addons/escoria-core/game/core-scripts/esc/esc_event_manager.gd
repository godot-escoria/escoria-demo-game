# A manager for running events
extends Node
class_name ESCEventManager

# Emitted when the event started execution
signal event_started(event_name)

# Emitted when an event is started in a channel of the background queue
signal background_event_started(channel_name, event_name)

# Emitted when the event did finish running
signal event_finished(return_code, event_name)

# Emitted when a background event was finished
signal background_event_finished(return_code, event_name, channel_name)


# A queue of events to run
var events_queue: Array = []

# A list of currently scheduled events
var scheduled_events: Array = []

# A list of constantly running events in multiple background channels
var background_events_queue: Dictionary = {}

# Currently running event
var _running_event: ESCEvent

# Currently running event in background channels
var _running_background_events: Dictionary = {}

# Whether the event manager is allowed to proceed with next event.
var _can_process_next_event = true

# Wether an event can be played on a specific channel
var _channels_state: Dictionary = {}


func _ready():
	self.pause_mode = Node.PAUSE_MODE_STOP
	

# Handle the events queue and scheduled events
func _process(delta: float) -> void:
	if events_queue.size() > 0 and _can_process_next_event:
		_can_process_next_event = false
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
				["_front"]
			)
		if not _running_event.is_connected(
			"interrupted", self, "_on_event_finished"
		):
			_running_event.connect(
				"interrupted", 
				self, 
				"_on_event_finished",
				["_front"]
			)
		
		emit_signal("event_started", _running_event.name)
		_running_event.run()
	for channel_name in background_events_queue.keys():
		if background_events_queue[channel_name].size() == 0:
			continue
		if (not channel_name in _channels_state) or \
				(channel_name in _channels_state and \
				_channels_state[channel_name]):
			_channels_state[channel_name] = false
			_running_background_events[channel_name] = \
				background_events_queue[channel_name].pop_front()
			escoria.logger.debug(
				"esc_event_manager",
				[
					"Popping event %s from background queue %s" % [
						_running_background_events[channel_name].name,
						channel_name
					]
				]
			)
			if not _running_background_events[channel_name].is_connected(
				"finished", self, "_on_event_finished"
			):
				_running_background_events[channel_name].connect(
					"finished", 
					self, 
					"_on_event_finished",
					[channel_name]
				)
			if not _running_background_events[channel_name].is_connected(
				"interrupted", self, "_on_event_finished"
			):
				_running_background_events[channel_name].connect(
					"interrupted", 
					self, 
					"_on_event_finished",
					[channel_name]
				)
			
			emit_signal(
				"background_event_started", 
				channel_name, 
				_running_background_events[channel_name].name
			)
			_running_background_events[channel_name].run()
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


# Queue the run of an event in a background channel
#
# #### Parameters
# - channel_name: Name of the channel to use
# - event: Event to run
func queue_background_event(channel_name: String, event: ESCEvent) -> void:
	if not channel_name in background_events_queue:
		background_events_queue[channel_name] = []
	
	background_events_queue[channel_name].append(event)


# The event finished running
func _on_event_finished(return_code: int, channel_name: String) -> void:
	var event
	if channel_name == "_front":
		event = _running_event
	else:
		event = _running_background_events[channel_name]
	escoria.logger.debug(
		"Event %s ended with return code %d" % [event.name, return_code]
	)
	event.disconnect("finished", self, "_on_event_finished")
	event.disconnect("interrupted", self, "_on_event_finished")
	
	if return_code == ESCExecution.RC_CANCEL:
		return_code = ESCExecution.RC_OK
	
	if channel_name == "_front":
		_running_event = null
		_can_process_next_event = true
		emit_signal(
			"event_finished", 
			return_code,
			event.name
		)
	else:
		_running_background_events[channel_name] = null
		_channels_state[channel_name] = true
		emit_signal(
			"background_event_finished", 
			return_code,
			event.name, 
			channel_name
		)


# Interrupt the events currently running.
func interrupt_running_event():
	if _running_event != null:
		_running_event.interrupt()
	for channel_name in _running_background_events.keys():
		if _running_background_events[channel_name] != null:
			_running_background_events[channel_name].interrupt()


# Clears the event queues.
func clear_event_queue():
	events_queue.clear()
	for channel_name in background_events_queue.keys():
		background_events_queue[channel_name].clear()
