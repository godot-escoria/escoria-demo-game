# A manager for running events
# There are different "channels" an event can run on.
# The usual events happen in the foreground channel _front, but
# additional event queues can be added as required.
# Additionally, events can be scheduled to be queued in the future
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


# A list of currently scheduled events
var scheduled_events: Array = []

# A list of constantly running events in multiple background channels
var events_queue: Dictionary = {}

# Currently running event in background channels
var _running_events: Dictionary = {}

# Wether an event can be played on a specific channel
var _channels_state: Dictionary = {}


# Make sure to stop when pausing the game
func _ready():
	self.pause_mode = Node.PAUSE_MODE_STOP
	

# Handle the events queue and scheduled events
#
# #### Parameters
# - delta: Time passed since the last process call
func _process(delta: float) -> void:
	for channel_name in events_queue.keys():
		if events_queue[channel_name].size() == 0:
			continue
		if (not channel_name in _channels_state) or \
				(channel_name in _channels_state and \
				_channels_state[channel_name]):
			_channels_state[channel_name] = false
			_running_events[channel_name] = \
				events_queue[channel_name].pop_front()
			escoria.logger.debug(
				"esc_event_manager",
				[
					"Popping event %s from background queue %s" % [
						_running_events[channel_name].name,
						channel_name
					]
				]
			)
			if not _running_events[channel_name].is_connected(
				"finished", self, "_on_event_finished"
			):
				_running_events[channel_name].connect(
					"finished", 
					self, 
					"_on_event_finished",
					[channel_name]
				)
			if not _running_events[channel_name].is_connected(
				"interrupted", self, "_on_event_finished"
			):
				_running_events[channel_name].connect(
					"interrupted", 
					self, 
					"_on_event_finished",
					[channel_name]
				)
			
			if channel_name == "_front":
				emit_signal(
					"event_started",
					_running_events[channel_name].name
				)
			else:
				emit_signal(
					"background_event_started", 
					channel_name, 
					_running_events[channel_name].name
				)
			_running_events[channel_name].run()
	for event in self.scheduled_events:
		(event as ESCScheduledEvent).timeout -= delta
		if (event as ESCScheduledEvent).timeout <= 0:
			self.scheduled_events.erase(event)
			self.events_queue['_front'].append(event.event)


# Queue a new event to run in the foreground
#
# #### Parameters
# - event: Event to run
func queue_event(event: ESCEvent) -> void:
	self.events_queue['_front'].append(event)


# Schedule an event to run after a timeout
#
# #### Parameters
# - event: Event to run
# - timeout: Number of seconds to wait before adding the event to the
#   front queue
func schedule_event(event: ESCEvent, timeout: float) -> void:
	scheduled_events.append(ESCScheduledEvent.new(event, timeout))


# Queue the run of an event in a background channel
#
# #### Parameters
# - channel_name: Name of the channel to use
# - event: Event to run
func queue_background_event(channel_name: String, event: ESCEvent) -> void:
	if not channel_name in events_queue:
		events_queue[channel_name] = []
	
	events_queue[channel_name].append(event)


# The event finished running
#
# #### Parameters
# - return_code: Return code of the finished event
# - channel_name: Name of the channel that the event came from
func _on_event_finished(return_code: int, channel_name: String) -> void:
	var event = _running_events[channel_name]
	escoria.logger.debug(
		"Event %s ended with return code %d" % [event.name, return_code]
	)
	event.disconnect("finished", self, "_on_event_finished")
	event.disconnect("interrupted", self, "_on_event_finished")
	
	if return_code == ESCExecution.RC_CANCEL:
		return_code = ESCExecution.RC_OK
	
	if channel_name == "_front":
		emit_signal(
			"event_finished", 
			return_code,
			event.name
		)
	else:
		_running_events[channel_name] = null
		_channels_state[channel_name] = true
		emit_signal(
			"background_event_finished", 
			return_code,
			event.name, 
			channel_name
		)


# Interrupt the events currently running.
func interrupt_running_event():
	for channel_name in _running_events.keys():
		if _running_events[channel_name] != null:
			_running_events[channel_name].interrupt()


# Clears the event queues.
func clear_event_queue():
	for channel_name in events_queue.keys():
		events_queue[channel_name].clear()
		

# Check wether a channel is free to run more events
#
# #### Parameters
# - name: Name of the channel to test
# **Returns** Wether the channel can currently accept a new event
func is_channel_free(name: String) -> bool:
	return _channels_state[name]
