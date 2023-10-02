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
const EVENT_RESUME = "resume"
const EVENT_NEW_GAME = "newgame"
const EVENT_READY = "ready"
const EVENT_ROOM_SELECTOR = "room_selector"
const EVENT_SETUP = "setup"
const EVENT_TRANSITION_IN = "transition_in"
const EVENT_TRANSITION_OUT = "transition_out"
const EVENT_CANT_REACH = "cant_reach"

const REQUIRED_EVENTS = [
	EVENT_INIT,
	EVENT_NEW_GAME
]

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

# Those commands that are currently running per channel.
var _running_commands: Dictionary = {}

# Channel currently being processed.
var _current_channel: String = ""

# Whether an event can be played on a specific channel
var _channels_state: Dictionary = {}

# Whether we're currently waiting for an async event to complete, per channel
var _yielding: Dictionary = {}

# Whether we're currently changing the scene.
var _changing_scene: bool = false setget set_changing_scene

# ESC "change_scene" command.
var _change_scene: ChangeSceneCommand


# Constructor
func _init():
	_change_scene = ChangeSceneCommand.new()


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
			_current_channel = channel_name
			_channels_state[channel_name] = false
			_running_events[channel_name] = \
				events_queue[channel_name].pop_front()
			escoria.logger.debug(
				self,
				"Popping event '%s' from background queue %s " % [
					_running_events[channel_name].get_event_name(),
					channel_name,
				] +
				"to source %s." % [_running_events[channel_name].source \
					if not _running_events[channel_name].source.empty()
					else "(unknown)"]
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
					_running_events[channel_name].get_event_name()
				)
			else:
				emit_signal(
					"background_event_started",
					channel_name,
					_running_events[channel_name].get_event_name()
				)

			var event_flags = _running_events[channel_name].get_flags()
			if event_flags & ESCEvent.FLAG_NO_TT:
				escoria.main.current_scene.game.tooltip_node.hide()

			if event_flags & ESCEvent.FLAG_NO_UI:
				escoria.main.current_scene.game.hide_ui()

			if event_flags & ESCEvent.FLAG_NO_SAVE:
				escoria.save_manager.save_enabled = false

			#var rc = _running_events[channel_name].run()
			#escoria.interpreter.reset()
			#var resolver: ESCResolver = ESCResolver.new(escoria.interpreter)
			var interpreter: ESCInterpreter = escoria.interpreter_factory.create_interpreter()
			var resolver: ESCResolver = ESCResolver.new(interpreter)
			var event = _running_events[channel_name]
			resolver.resolve(event)
			
			#var rc = escoria.interpreter.interpret(event)
			var rc = interpreter.interpret(event)

			if rc is GDScriptFunctionState:
				#_yielding[channel_name] = true
				rc = yield(rc, "completed")
				#_yielding[channel_name] = false

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

	if _changing_scene:
		return ESCExecution.RC_WONT_QUEUE

	if channel == CHANNEL_FRONT:
		queue_event(script_object.events[event])
	else:
		queue_background_event(
			channel,
			script_object.events[event]
		)
	if block:
		if channel == CHANNEL_FRONT:
			var rc = yield(self, "event_finished")
			while rc[1] != event:
				rc = yield(self, "event_finished")
			return rc[0]
		else:
			var rc = yield(self, "background_event_finished")
			while rc[1] != event and rc[2] != channel:
				rc = yield(self, "background_event_finished")
			return rc[0]

	return ESCExecution.RC_OK


# Queue a new event to run in the foreground
#
# #### Parameters
# - event: Event to run
# - force:
# - as_first: force the event to be the first in queue
func queue_event(event: ESCEvent, force: bool = false, as_first = false) -> void:
	if _changing_scene and not force:
		escoria.logger.info(
			self,
			"Changing scenes. Won't queue event '%s'." % event.get_event_name()
		)
		return

	# Don't queue the same event more than once in a row.
	var last_event = _get_last_event_queued(CHANNEL_FRONT)

	# Check the queue first to see if appending the event will result in
	# consecutive occurrences of the event. If not, be sure to check if the same
	# event is currently running.
	if last_event != null and last_event.get_event_name() == event.get_event_name():
		var message = "Event '%s' is already the most-recently queued event in channel '%s'." + \
			" Won't be queued again."

		escoria.logger.debug(self, message % [event.get_event_name(), CHANNEL_FRONT])
		return
	elif _is_event_running(event, CHANNEL_FRONT):
		# Don't queue the same event if it's already running.
		escoria.logger.debug(
			self,
			"Event %s already running in channel '%s'. Won't be queued."
				% [event.get_event_name(), CHANNEL_FRONT]
		)

		return

	escoria.logger.debug(
		self,
		"Queueing event %s in channel %s." % [event.get_event_name(), CHANNEL_FRONT]
	)
	if as_first:
		self.events_queue[CHANNEL_FRONT].push_front(event)
	else:
		self.events_queue[CHANNEL_FRONT].append(event)


# Schedule an event to run after a timeout
#
# #### Parameters
# - event: Event to run
# - timeout: Number of seconds to wait before adding the event to the
#   front queue
# - object: Target object
func schedule_event(event: ESCEvent, timeout: float, object: String) -> void:
	scheduled_events.append(ESCScheduledEvent.new(event, timeout, object))


# Queue the run of an event in a background channel
#
# #### Parameters
# - channel_name: Name of the channel to use
# - event: Event to run
func queue_background_event(channel_name: String, event: ESCGrammarStmts.Event) -> void:
	if not channel_name in events_queue:
		events_queue[channel_name] = []

	# Don't queue the same event more than once in a row.
	var last_event = _get_last_event_queued(channel_name)

	# Check the queue first to see if appending the event will result in
	# consecutive occurrences of the event. If not, be sure to check if the same
	# event is currently running.
	if last_event != null and last_event.get_event_name() == event.get_event_name():
		var message = "Event '%s' is already the most-recently queued event in channel '%s'." + \
			" Won't be queued again."

		escoria.logger.debug(self, message % [event.get_event_name(), channel_name])
		return
	elif _is_event_running(event, CHANNEL_FRONT):
		# Don't queue the same event if it's already running.
		escoria.logger.debug(
			self,
			"Event %s already running in channel '%s'. Won't be queued."
				% [event.get_event_name(), channel_name]
		)

		return

	events_queue[channel_name].append(event)


# Interrupt the events currently running and any that are pending.
#
# #### Parameters
# - exceptions: an optional list of events which should be left running or queued
func interrupt(exceptions: PoolStringArray = []) -> void:
	if escoria.main.current_scene != null \
			and escoria.main.current_scene.player != null \
			and escoria.main.current_scene.player.is_moving():
		escoria.main.current_scene.player.stop_walking_now()

	for channel_name in _running_events.keys():
		if _running_events[channel_name] != null and not _running_events[channel_name].get_event_name() in exceptions:
			escoria.logger.debug(
				self,
				"Interrupting running event %s in channel %s..."
						% [_running_events[channel_name].get_event_name(), channel_name])
			_running_events[channel_name].interrupt()
			_channels_state[channel_name] = true

	var events_to_clear: Array = []

	for channel_name in events_queue.keys():
		if events_queue[channel_name] != null:
			var found_exception: bool = false

			for event in events_queue[channel_name]:
				if event.get_event_name() in exceptions:
					found_exception = true
					continue

				escoria.logger.debug(
					self,
					"Interrupting queued event %s in channel %s..."
							% [event.get_event_name(), channel_name])
				#event.interrupt() # Is this even needed if the event hasn't started and we're just going to remove it from the queue?
				events_to_clear.append(event)

			# If we found an exception, we can't just clear out the entire
			# channel's queue and so we remove everything but the exceptions in
			# the channel. Otherwise, we're safe to just clear it out.
			if found_exception:
				for event in events_to_clear:
					if events_queue[channel_name].has(event):
						events_queue[channel_name].erase(event)
			else:
				events_queue[channel_name].clear()


func interrupt_channel(channel_name: String):
	for command in _running_commands.get(channel_name, []):
		command.interrupt()


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
func get_running_event(name: String) -> ESCGrammarStmts.Event:
	return _running_events[name] if name in _running_events else null


# Setter for _changing_scene.
#
# #### Parameterse
# - value: boolean value to set _changing_scene to
func set_changing_scene(p_is_changing_scene: bool) -> void:
	escoria.logger.trace(
		self,
		"Setting _changing_scene to %s." % p_is_changing_scene
	)

	_changing_scene = p_is_changing_scene

	# If we're changing scenes, interrupt any (other) running events and purge
	# all event queues.
	if _changing_scene:
		interrupt([
			EVENT_INIT,
			EVENT_EXIT_SCENE,
			EVENT_LOAD,
			EVENT_RESUME,
			_change_scene.get_command_name()
		])


### This probably won't work sicne _current_channel could have changed after
### a yielding command resumes. Also the event itself isn't logged, just the command,
### creating a problem.

# Adds a currently-running command to the current channel.
func add_running_command(command: ESCCommand):
	if _running_commands.get(_current_channel, []) == []:
		_running_commands[_current_channel] = [command]
	else:
		_running_commands[_current_channel].append(command)


# Removes the specified command from the current channel.
func running_command_finished(command: ESCCommand):
	if command in _running_commands[_current_channel]:
		_running_commands[_current_channel].erase(command)


# The event finished running
#
# #### Parameters
# - finished_event: statement object representing the event that finished
# - finished_statement: statement object representing the "deepest" statement (most likely a command)
#   that just completed; this is useful for interrupted or failed statements especially
# - return_code: Return code of the finished event
# - channel_name: Name of the channel that the event came from
#func _on_event_finished(finished_event: ESCStatement, finished_statement: ESCStatement, return_code: int, channel_name: String) -> void:
func _on_event_finished(finished_event, finished_statement, return_code: int, channel_name: String) -> void:
	var event = _running_events[channel_name]
	if not event:
		escoria.logger.warn(
			self,
			"Event '%s' finished without being in _running_events[%s]."
				% [finished_event.get_event_name(), channel_name]
		)
		return

	escoria.logger.debug(
		self,
		"Event '%s' ended with return code %d." % [event.get_event_name(), return_code]
	)

	var event_flags = event.get_flags()
	if event_flags & ESCEvent.FLAG_NO_TT:
		escoria.main.current_scene.game.tooltip_node.show()

	if event_flags & ESCEvent.FLAG_NO_UI:
		escoria.main.current_scene.game.show_ui()

	if event_flags & ESCEvent.FLAG_NO_SAVE:
		escoria.save_manager.save_enabled = true

	# If the return code was RC_CANCEL due to an event finishing with "stop" command for example
	# we convert it to RC_OK so that other processed waiting for RC_OK can carry on.
	#
	# We also make sure that a failed command/event doesn't leave the game in a state where it
	# isn't accepting inputs, e.g. if a previous command in the event was `accept_input NONE`.
	if return_code == ESCExecution.RC_CANCEL:
		return_code = ESCExecution.RC_OK
	elif return_code == ESCExecution.RC_ERROR:
		_generate_statement_error_warning(finished_statement, event.get_event_name())

		escoria.inputs_manager.input_mode = escoria.inputs_manager.INPUT_ALL

	_running_events[channel_name] = null
	_channels_state[channel_name] = true

	if channel_name == CHANNEL_FRONT:
		emit_signal(
			"event_finished",
			return_code,
			event.get_event_name()
		)

		if finished_event.name == EVENT_LOAD \
				and escoria.current_state == escoria.GAME_STATE.LOADING:
			escoria.save_manager.is_loading_game = false
			escoria.save_manager.emit_signal("game_finished_loading")
			escoria.current_state = escoria.GAME_STATE.DEFAULT
			escoria.main.current_scene.get_tree().call_group(
				escoria.GROUP_ITEM_TRIGGERS, "connect_trigger_events")
		elif finished_event.name == EVENT_NEW_GAME:
			escoria.creating_new_game = false
	else:
		emit_signal(
			"background_event_finished",
			return_code,
			event.get_event_name(),
			channel_name
		)


# Gets the event at the tail of the specified channel's event queue, if one
# exists.
#
# #### Parameters
# - channel_name: The name of the channel to check.
#
# *Returns* the last ESCEvent queued for the given channel, or null if the
# channel's queue is empty.
func _get_last_event_queued(channel_name: String) -> ESCEvent:
	if self.events_queue[channel_name].size() > 0:
		return self.events_queue[channel_name].back()

	return null


# Checks to see if the specified event is already running in the given channel.
#
# #### Parameters
# - event: The event to check to see if it's already running.
# - channel_name: The name of the channel to check.
#
# *Returns* true iff event is currently running in the specified channel.
func _is_event_running(event: ESCGrammarStmts.Event, channel_name: String) -> bool:
	var running_event: ESCGrammarStmts.Event = get_running_event(channel_name)

	return running_event != null and running_event.get_event_name() == event.get_event_name()


# Generates a logger warning concerning an errored-out statement.
func _generate_statement_error_warning(statement: ESCStatement, event_name: String) -> void:
	var warning_string: String = "Statement '%s' returned an error in event '%s'" \
		% [statement.get_name(), event_name]

	if statement is ESCCommand and statement.parameters.size() > 0:
		var statement_params: String = "[" + PoolStringArray(statement.parameters).join(", ") + "]"

		warning_string += " with parameters: %s" % statement_params

	warning_string += ". Resetting input mode to 'ALL'."

	escoria.logger.warn(
		self,
		warning_string
	)


# Save the running event in the savegame, if any.
#
# #### Parameters
# - p_savegame: ESCSaveGame resource that holds all data of the save
func save_game(p_savegame: ESCSaveGame) -> void:
	# Running event
	var running_event = get_running_event(CHANNEL_FRONT)
	if running_event != null:
		p_savegame.events.running_event = running_event.exported()

	# Scheduled events
	var sched_events_array: Array = []
	for sched_event in scheduled_events:
		sched_events_array.push_back(sched_event.exported())
	p_savegame.events.sched_events = sched_events_array

	# Events queue
	var events_queue_dict: Dictionary = {}
	for ev_key in events_queue:
		var events_queue_for_key: Array = []
		for ev in events_queue[ev_key]:
			events_queue_for_key.push_back(ev.exported())
		events_queue_dict[ev_key] = events_queue_for_key
	p_savegame.events.events_queue = events_queue_dict


# Recursive function that fills an array with statement ids
# to resume from the running event.
#
# #### Parameters
# - p_running_event: Dictionary containing the nested ESCStatements (first one should be an ESCEvent)
# - current_statement_ids: Array of statement ids in the considered event.
func _get_current_statement_ids_in_running_event(p_running_event: Dictionary, current_statement_ids: Array):
	if p_running_event.current_statement == null:
		return
	else:
		current_statement_ids.push_back(p_running_event.from_statement_id)
		_get_current_statement_ids_in_running_event(p_running_event.current_statement, current_statement_ids)


# Recursive function that sets the statement ids to resume in the ongoing event
# from a list of  statementids.
#
# #### Parameters
# - running_event: The ESCStatement (on root call, should be an ESCEvent)
# - statement_ids_arr: Array of statement ids to set
func _set_current_statements_in_running_event(running_event: ESCStatement, statement_ids_arr: Array):
	if statement_ids_arr.empty() or running_event.statements.empty():
		return
	else:
		var id = statement_ids_arr.pop_front()
		running_event.current_statement = running_event.statements[id]
		running_event.from_statement_id = id
		_set_current_statements_in_running_event(running_event.current_statement, statement_ids_arr)


# Sets the running event from a Dictionary (loaded from a savegame)
#
# #### Parameters
# - p_running_event: The Dictionary containing the event data
func set_running_event_from_savegame(p_running_event: Dictionary):
	# Get ids of the statements to set as current
	var statement_ids_arr: Array = []
	_get_current_statement_ids_in_running_event(p_running_event, statement_ids_arr)
	var script: ESCScript = escoria.esc_compiler.load_esc_file(p_running_event.source)
	var running_event: ESCEvent = script.events[p_running_event.original_name] # usually "setup" or "ready"
	running_event.name = EVENT_RESUME
	_set_current_statements_in_running_event(running_event, statement_ids_arr)
	queue_event(running_event)


# Sets the scheduled events from an array (loaded from a savegame)
#
# #### Parameters
# - p_scheduled_events: The array containing the scheduled event data
func set_scheduled_events_from_savegame(p_scheduled_events: Array):
	for sched_ev in p_scheduled_events:
		var script: ESCScript = escoria.esc_compiler.load_esc_file(sched_ev.event.source)
		var ev: ESCEvent = script.events[sched_ev.event.original_name]
		escoria.event_manager.schedule_event(ev, sched_ev.timeout, sched_ev.object)
