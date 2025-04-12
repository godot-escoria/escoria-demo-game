## Manager for running events.
##
## There are different "channels" an event can run on. The usual events happen in 
## the foreground channel _front, but additional event queues can be added as required.
## Additionally, events can be scheduled to be queued in the future.
extends Node
class_name ESCEventManager


## Emitted when the event has begun execution.
signal event_started(event_name)

## Emitted when an event is started in a channel of the background queue.
signal background_event_started(channel_name, event_name)

## Emitted when the event has finished running.
signal event_finished(return_code, event_name)

## Emitted when a background event has finished.
signal background_event_finished(return_code, event_name, channel_name)


# Pre-defined ASHES events.

## Used for local processing.
const EVENT_PRINT = "print"

## Used for local processing.
const EVENT_EXIT_SCENE = "exit_scene"

## Used for local processing.
const EVENT_INIT = "init"

## Used for local processing.
const EVENT_LOAD = "load"

## Used for local processing.
const EVENT_RESUME = "resume"

## Used for local processing.
const EVENT_NEW_GAME = "newgame"

## Used for local processing.
const EVENT_READY = "ready"

## Used for local processing.
const EVENT_SETUP = "setup"

## Used for local processing.
const EVENT_TRANSITION_IN = "transition_in"

## Used for local processing.
const EVENT_TRANSITION_OUT = "transition_out"

## Used for local processing.
const EVENT_CANT_REACH = "cant_reach"

## Events that MUST exist in order for Escoria to run properly.
const REQUIRED_EVENTS = [
	EVENT_INIT,
	EVENT_NEW_GAME
]

# Event channel names.

## The primary channel for running events.
const CHANNEL_FRONT = "_front"


## A list of currently scheduled events.
var scheduled_events: Array = []

## A list of constantly running events, possibly in multiple background channels.
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
var _changing_scene: bool = false: set = set_changing_scene

# ESC "change_scene" command.
var _change_scene: ChangeSceneCommand


# Constructor
func _init():
	_change_scene = ChangeSceneCommand.new()


# Make sure to stop when pausing the game
func _ready():
	name = "event_manager"
	self.process_mode = Node.PROCESS_MODE_PAUSABLE


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
				"to source %s." % _running_events[channel_name].source \
					if not _running_events[channel_name].source.is_empty()
					else "(unknown)"
			)
			if not _running_events[channel_name].is_connected(
				"finished", _on_event_finished
			):
				_running_events[channel_name].finished.connect(
					_on_event_finished.bind(channel_name),
					CONNECT_ONE_SHOT
				)
			if not _running_events[channel_name].is_connected(
				"interrupted", _on_event_finished
			):
				_running_events[channel_name].interrupted.connect(
					_on_event_finished.bind(channel_name),
					CONNECT_ONE_SHOT
				)

			if channel_name == CHANNEL_FRONT:
				event_started.emit(
					_running_events[channel_name].get_event_name()
				)
			else:
				background_event_started.emit(
					channel_name,
					_running_events[channel_name].get_event_name()
				)

			var event_flags = _running_events[channel_name].get_flags()
			if event_flags & ESCEvent.FLAGS.NO_TT:
				escoria.main.current_scene.game.tooltip_node.hide()

			if event_flags & ESCEvent.FLAGS.NO_UI:
				escoria.main.current_scene.game.hide_ui()

			if event_flags & ESCEvent.FLAGS.NO_SAVE:
				escoria.save_manager.save_enabled = false

			#var rc = _running_events[channel_name].run()
			#escoria.interpreter.reset()
			#var resolver: ESCResolver = ESCResolver.new(escoria.interpreter)
			var interpreter: ESCInterpreter = ESCInterpreterFactory.create_interpreter()
			var resolver: ESCResolver = ESCResolver.new(interpreter)
			var event = _running_events[channel_name]

			escoria.logger.trace(
				self,
				"Processing event '%s' from script '%s'." \
					% [
						event.get_name().get_lexeme(),
						event.get_name().get_filename() if event.get_name().get_filename() else "<internal>"
					]
			)

			resolver.resolve(event)

			var rc = await interpreter.interpret(event)

			#if rc is GDScriptFunctionState:
				#_yielding[channel_name] = true
				#rc = await (rc, "completed")
				#_yielding[channel_name] = false

	for event in self.scheduled_events:
		(event as ESCScheduledEvent).timeout -= delta
		if (event as ESCScheduledEvent).timeout <= 0:
			self.scheduled_events.erase(event)
			self.events_queue[CHANNEL_FRONT].append(event.event)


## Queues a new event based on input from an ASHES command, most likely `queue_event`.[br]
##[br]
## #### Parameters[br]
## * script_object: Compiled script object, i.e. the one with the event to queue.[br]
## * event: Name of the event to queue.[br]
## * channel: Channel to run the event on (default: `_front`).[br]
## * block: Whether to wait for the queue to finish. This is only possible, if
##   the queued event is not to be run on the same event as this command
##   (default: `false`).[br]
##[br]
## **Returns** indicator of success/status (from the `ESCExecution` enum).
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
			var rc = await self.event_finished
			while rc[1] != event:
				rc = await self.event_finished
			return rc[0]
		else:
			var rc = await self.background_event_finished
			while rc[1] != event and rc[2] != channel:
				rc = await self.background_event_finished
			return rc[0]

	return ESCExecution.RC_OK


## Queues a new event to run in the foreground.[br]
##[br]
## #### Parameters[br]
## * event: The event to run.[br]
## * force: (optional) Events won't normally queue during scene changes. This 
## parameter overrides that beahviour.[br]
## * as_first: (optional) Put the event at the head of the queue.[br]
func queue_event(event: ESCGrammarStmts.Event, force: bool = false, as_first = false) -> void:
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


## Schedules an event to run after a timeout.[br]
##[br]
## #### Parameters[br]
## * event: The event to run.[br]
## * timeout: Number of seconds to wait before adding the event to the
## front queue.[br]
## * object: The target object.
func schedule_event(event: ESCGrammarStmts.Event, timeout: float, object: String) -> void:
	scheduled_events.append(ESCScheduledEvent.new(event, timeout, object))


## Queues an event to run in a background channel.[br]
##[br]
## #### Parameters[br]
## * channel_name: The name of the channel to use.[br]
## * event: The event to run; must be of type `ESCGrammarEvents.Event`.
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


## Interrupts the events currently running and any that are pending.[br]
##[br]
## #### Parameters[br]
## * exceptions: An optional list of events which should be left running or queued.
# - stop_walking: boolean value (default true) determining whether the player
# (if any) has to be interrupted walking or not.
func interrupt(exceptions: PackedStringArray = [], stop_walking = true) -> void:
	if stop_walking \
			and escoria.main.current_scene != null \
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


## Interrupts any events in the specified channel.[br]
##[br]
## #### Parameters[br]
## * channel_name: The name of the channel containing the events to be interrupted.
func interrupt_channel(channel_name: String) -> void:
	for command in _running_commands.get(channel_name, []):
		command.interrupt()


## Clears the event queues.
func clear_event_queue() -> void:
	for channel_name in events_queue.keys():
		events_queue[channel_name].clear()


## Checks whether a channel is free to run more events.[br]
##[br]
## #### Parameters[br]
## * name: The name of the channel to test.[br]
##[br]
## **Returns** whether the channel can currently accept a new event.
func is_channel_free(name: String) -> bool:
	return _channels_state[name] if name in _channels_state else true


## Gets the currently running event in a channel.[br]
##[br]
## #### Parameters[br]
## - name: The ame of the channel.[br]
##[br]
## **Returns** the currently running event of type `ESCGrammarStmts.Event`, or 
## `null` if there is none.
func get_running_event(name: String) -> ESCGrammarStmts.Event:
	return _running_events[name] if name in _running_events else null


## Setter for _changing_scene.[br]
##[br]
## #### Parameters[br]
## - value: `boolean` value to set `_changing_scene` to.
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
			EVENT_NEW_GAME,
			EVENT_LOAD,
			EVENT_RESUME,
			_change_scene.get_command_name()
		])


# This probably won't work since _current_channel could have changed after
# a yielding command resumes. Also the event itself isn't logged, just the command,
# creating a problem.

## Adds a currently-running command to the current channel.[br]
##[br]
## #### Parameters[br]
## * command: The `ESCCommand` to be added to the current channel.
func add_running_command(command: ESCCommand) -> void:
	if _running_commands.get(_current_channel, []) == []:
		_running_commands[_current_channel] = [command]
	else:
		_running_commands[_current_channel].append(command)


## Removes the specified command from the current channel.[br]
##[br]
## #### Parameters[br]
## * command: The `ESCCommand` to be removed from the current channel.
func running_command_finished(command: ESCCommand) -> void:
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
	if event_flags & ESCEvent.FLAGS.NO_TT:
		escoria.main.current_scene.game.tooltip_node.show()

	if event_flags & ESCEvent.FLAGS.NO_UI:
		escoria.main.current_scene.game.show_ui()

	if event_flags & ESCEvent.FLAGS.NO_SAVE:
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
		event_finished.emit(
			return_code,
			event.get_event_name()
		)
	else:
		background_event_finished.emit(
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
func _get_last_event_queued(channel_name: String):
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
		var statement_params: String = "[" + ", ".join(PackedStringArray(statement.parameters)) + "]"

		warning_string += " with parameters: %s" % statement_params

	warning_string += ". Resetting input mode to 'ALL'."

	escoria.logger.warn(
		self,
		warning_string
	)


## Save the running event in the savegame, if any.[br]
## #### Parameters[br]
## * p_savegame: `ESCSaveGame` resource that holds all save data.
func save_game(p_savegame: ESCSaveGame) -> void:
	# Scheduled events
	var sched_events_array: Array = []
	for sched_event in scheduled_events:
		sched_events_array.push_back((sched_event as ESCScheduledEvent).exported())
	p_savegame.events.sched_events = sched_events_array
