# `sched_event time object event`
#
# Schedules an event to run at a later time.
#
# If another event is already running when the scheduled
# event is supposed to start, execution of the scheduled event
# begins when the already-running event ends.
#
# **Parameters**
#
# - *time*: Time in seconds until the scheduled event starts
# - *object*: Global ID of the ESCItem that holds the ESC script
# - *event*: Name of the event to schedule
#
# @ESC
extends ESCBaseCommand
class_name SchedEventCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3,
		[[TYPE_FLOAT, TYPE_INT], TYPE_STRING, TYPE_STRING],
		[null, null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[1]) and not _is_current_room(arguments[1]):
		raise_invalid_object_error(self, arguments[1])
		return false

	var node = _get_scripted_node(arguments[1])

	if not "esc_script" in node or node.esc_script == "":
		raise_error(
			self,
			"Object/room with global id '%s' has no ESC script." % arguments[1]
		)
		return false

	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)

	if not arguments[2] in esc_script.events:
		raise_error(
			self,
			"Event with name '%s' not found." % arguments[2]
		)
		return false
	return true


# Return whether global_id represents the current room the player is in.
func _is_current_room(global_id: String) -> bool:
	return escoria.main.current_scene.global_id == global_id


# Run the command
func run(command_params: Array) -> int:
	var node = _get_scripted_node(command_params[1])

	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)

	escoria.event_manager.schedule_event(
		escoria.object_manager.get_object(command_params[1])\
			.events[command_params[2]],
		command_params[0],
		command_params[1]
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass


# Fetches the object node or current room containing the desired ESC script.
#
# PRE: If global_id represents a room, then `escoria.main.current_scene` must be valid.
#
# **Parameters**
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
