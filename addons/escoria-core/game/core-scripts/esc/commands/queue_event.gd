## `queue_event(object: String, event: String[, channel: String[, block: Boolean]])`
##
## Queue an event to run. If you queue multiple events on a channel and none of them are blocking events, all events will effectively run at the same time. As the events are placed on the channel's queue, if one event contains a blocking command, the next event on that channel's queue won't be processed until the blocking command finishes.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Object that holds the ESC script with the event|yes|[br]
## |event|`String`|Name of the event to queue|yes|[br]
## |channel|`String`|Channel to run the event on (default: `_front`). Using a previously unused channel name will create a new channel.|no|[br]
## |block|`Boolean`|Whether to wait for the queue to finish. This is only possible, if the queued event is not to be run on the same event as this command (default: `false`)|no|[br]
## [br]
## @ASHES
## @COMMAND
extends ESCBaseCommand
class_name QueueEventCommand


## The descriptor of the arguments of this command.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the descriptor of the arguments of this command. The argument descriptor for this command. (`ESCCommandArgumentDescriptor`)
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_BOOL],
		[null, null, "_front", false]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|The arguments to validate.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the arguments are valid, false otherwise. (`bool`)
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]) and not _is_current_room(arguments[0]):
		raise_error(self, "No object or room with global id '%s' found." % arguments[0])
		return false

	var node = _get_scripted_node(arguments[0])

	if not "esc_script" in node or node.esc_script == "":
		raise_error(
			self,
			"Object/room with global id '%s' has no ESC script." % arguments[0]
		)
		return false

	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)

	if not arguments[1] in esc_script.events:
		raise_error(
			self,
			"Event with name '%s' not found." % arguments[1]
		)
		return false

	if arguments[3] and not escoria.event_manager.is_channel_free(arguments[2]):
		raise_error(
			self,
			"The queue '%s' can't currently accept new events." % arguments[2]
		)
		return false

	return true


## Whether global_id represents the current room the player is in.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |global_id|`String`|The global ID to check.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns whether global_id represents the current room the player is in. True if global_id represents the current room, false otherwise. (`bool`)
func _is_current_room(global_id: String) -> bool:
	return escoria.main.current_scene.global_id == global_id


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|Command parameters `[global_id, event_name, channel, block]` passed to the execution.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the execution result code. (`int`)
func run(arguments: Array) -> int:
	var node = _get_scripted_node(arguments[0])

	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)

	return await escoria.event_manager.queue_event_from_esc(
		esc_script,
		arguments[1], ## event name
		arguments[2], ## channel name
		arguments[3]  ## whether to block
	)


## Function called when the command is interrupted.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	# Do nothing
	pass


# Fetches the object node or current room containing the desired ESC script.
#
# PRE: If global_id represents a room, then `escoria.main.current_scene` must be valid.
#
## #### Parameters
#
# - global_id: ID of the object or room with the desired ESC script.
#
# *Returns*
#
# The object node corresponding to global_id, or the current room if global_id is invalid or does
# not refer to an object registered with the object manager.
func _get_scripted_node(global_id: String):
	var node = null

	if escoria.object_manager.has(global_id):
		node = escoria.object_manager.get_object(
			global_id
		).node
	else:
		node = escoria.main.current_scene

	return node
