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


# Pre-defined ESC events
const EVENT_PRINT = "print"
const EVENT_EXIT_SCENE = "exit_scene"
const EVENT_INIT = "init"
const EVENT_LOAD = "load"
const EVENT_NEW_GAME = "newgame"
const EVENT_READY = "ready"
const EVENT_ROOM_SELECTOR = "room_selector"
const EVENT_SETUP = "setup"
const EVENT_TRANSITION_IN = "transition_in"
const EVENT_TRANSITION_OUT = "transition_out"


# Event channel names
const CHANNEL_FRONT = "_front"


# A list of currently scheduled events
var scheduled_events: Array = []

# A list of constantly running events in multiple background channels
var events_queue: Dictionary = {
	CHANNEL_FRONT: []
}

# Currently running event in background channels
var _running_events: Dictionary = {}

# Whether an event can be played on a specific channel
var _channels_state: Dictionary = {}

# Whether we're currently waiting for an async event to complete, per channel
var _yielding: Dictionary = {}


# Make sure to stop when pausing the game
func _ready():
	self.pause_mode = Node.PAUSE_MODE_STOP


# Handle the events queue and scheduled events
#
# #### Parameters
# - delta: Time passed since the last process call
func _process(delta: float) -> void:
	var channel_yielding: bool

	for channel_name in events_queue.keys():
		channel_yielding = _yielding.get(channel_name, false)

		if events_queue[channel_name].size() == 0 or channel_yielding:
			continue
		if is_channel_free(channel_name):
			_channels_state[channel_name] = false
			_running_events[channel_name] = \
				events_queue[channel_name].pop_front()
			escoria.logger.debug(
				"esc_event_manager",
				[
					"Popping event '%s' from background queue %s" % [
						_running_events[channel_name].name,
						channel_name,
					],
					"from source %s" % _running_events[channel_name].source \
						if not _running_events[channel_name].source.empty()
						else "(unknown)",
				]
			)
			if not _running_events[channel_name].is_connected(
				"finished", self, "_on_event_finished"
			):
				_running_events[channel_name].connect(
					"finished",
					self,
					"_on_event_finished",
					[channel_name],
					CONNECT_ONESHOT
				)
			if not _running_events[channel_name].is_connected(
				"interrupted", self, "_on_event_finished"
			):
				_running_events[channel_name].connect(
					"interrupted",
					self,
					"_on_event_finished",
					[channel_name],
					CONNECT_ONESHOT
				)

			if channel_name == CHANNEL_FRONT:
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

			var event_flags = _running_events[channel_name].flags
			if event_flags & ESCEvent.FLAG_NO_TT:
				escoria.main.current_scene.game.tooltip_node.hide()

			if event_flags & ESCEvent.FLAG_NO_UI:
				escoria.main.current_scene.game.hide_ui()

			if event_flags & ESCEvent.FLAG_NO_SAVE:
				escoria.save_manager.save_enabled = false

			var rc = _running_events[channel_name].run()

			if rc is GDScriptFunctionState:
				_yielding[channel_name] = true
				rc = yield(rc, "completed")
				_yielding[channel_name] = false

	for event in self.scheduled_events:
		(event as ESCScheduledEvent).timeout -= delta
		if (event as ESCScheduledEvent).timeout <= 0:
			self.scheduled_events.erase(event)
			self.events_queue[CHANNEL_FRONT].append(event.event)


# Queue a new event based on input from an ESC command, most likely "queue_event"
#
# #### Parameters
# - script_object: Compiled script object, i.e. the one with the event to queue
# - event: Name of the event to queue
# - channel: Channel to run the event on (default: `_front`)
# - block: Whether to wait for the queue to finish. This is only possible, if
#   the queued event is not to be run on the same event as this command
#   (default: `false`)
#
# **Returns** indicator of success/status
func queue_event_from_esc(script_object: ESCScript, event: String,
	channel: String, block: bool) -> int:

	if channel == CHANNEL_FRONT:
		escoria.event_manager.queue_event(script_object.events[event])
	else:
		escoria.event_manager.queue_background_event(
			channel,
			script_object.events[event]
		)
	if block:
		if channel == CHANNEL_FRONT:
			var rc = yield(escoria.event_manager, "event_finished")
			while rc[1] != event:
				rc = yield(escoria.event_manager, "event_finished")
			return rc
		else:
			var rc = yield(
				escoria.event_manager,
				"background_event_finished"
			)
			while rc[1] != event and rc[2] != channel:
				rc = yield(
					escoria.event_manager,
					"background_event_finished"
				)
			return rc

	return ESCExecution.RC_OK


# Queue a new event to run in the foreground
#
# #### Parameters
# - event: Event to run
func queue_event(event: ESCEvent) -> void:
	self.events_queue[CHANNEL_FRONT].append(event)


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


# Interrupt the events currently running.
func interrupt_running_event():
	for channel_name in _running_events.keys():
		if _running_events[channel_name] != null:
			_running_events[channel_name].interrupt()
			_channels_state[channel_name] = true


# Clears the event queues.
func clear_event_queue():
	for channel_name in events_queue.keys():
		events_queue[channel_name].clear()


# Check whether a channel is free to run more events
#
# #### Parameters
# - name: Name of the channel to test
# **Returns** Whether the channel can currently accept a new event
func is_channel_free(name: String) -> bool:
	return _channels_state[name] if name in _channels_state else true


# Get the currently running event in a channel
#
# #### Parameters
# - name: Name of the channel
# **Returns** The currently running event or null
func get_running_event(name: String) -> ESCEvent:
	return _running_events[name] if name in _running_events else null


# The event finished running
#
# #### Parameters
# - finished_statement: statement object that finished
# - return_code: Return code of the finished event
# - channel_name: Name of the channel that the event came from
func _on_event_finished(finished_statement: ESCStatement, return_code: int, channel_name: String) -> void:
	var event = _running_events[channel_name]
	if not event:
		escoria.logger.report_warnings(
			"esc_event_manager.gd:_on_event_finished()",
			[
				"Event %s finished without being in _running_events[%s]"
					% [finished_statement.name, channel_name]
			]
		)
		return

	escoria.logger.debug(
		"Event %s ended with return code %d" % [event.name, return_code]
	)

	var event_flags = event.flags
	if event_flags & ESCEvent.FLAG_NO_TT:
		escoria.main.current_scene.game.tooltip_node.show()

	if event_flags & ESCEvent.FLAG_NO_UI:
		escoria.main.current_scene.game.show_ui()

	if event_flags & ESCEvent.FLAG_NO_SAVE:
		escoria.save_manager.save_enabled = true

	_running_events[channel_name] = null
	_channels_state[channel_name] = true

	if channel_name == CHANNEL_FRONT:
		emit_signal(
			"event_finished",
			return_code,
			event.name
		)
	else:
		emit_signal(
			"background_event_finished",
			return_code,
			event.name,
			channel_name
		)
