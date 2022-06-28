# Basic features and informations about ESC executions
extends Resource
class_name ESCExecution


# Return codes handled by events
# * RC_OK: Event run okay
# * RC_CANCEL: Cancel all scheduled and queued events. This return code tells the Event Manager
# that no execution is required for this command (such as "stop" and "repeat")
# * RC_ERROR: Error running a command
# * RC_REPEAT: Repeat the current scope from the beginning
# * RC_INTERRUPTED: Event was interrupted
# * RC_WONT_QUEUE: Event won't or can't be queued
enum {RC_OK, RC_CANCEL, RC_ERROR, RC_REPEAT, RC_INTERRUPTED, RC_WONT_QUEUE}
