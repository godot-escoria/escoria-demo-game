## `force_event_flag("<object_id>", "<event name>", "<flag>")`
##
## Sets the event flag to "flag" value for "object_id" object's event "event_name".
##
## **Parameters**
##
## - *object_id*: Id of the object
## - *event_name*: name of the event
## - *flag*: flag name to force as string
##
## @ESC
extends ESCBaseCommand
class_name ForceEventFlagCommand


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3,
		[TYPE_STRING, TYPE_STRING, TYPE_STRING],
		[null, null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false
	if not escoria.object_manager.get_object(arguments[0]):
		raise_error(self, "Invalid object '%s'." % arguments[0])
		return false
	if not ESCEvent.FLAGS.has(arguments[2]):
		raise_error(self, "Invalid flag name '%s'." % arguments[2])
		return false
	
	return true


# Run the command
func run(command_params: Array) -> int:
	var object: ESCObject = escoria.object_manager.get_object(command_params[0])
	escoria.action_manager.force_event_flag(
		object, 
		command_params[1], 
		command_params[2])
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
