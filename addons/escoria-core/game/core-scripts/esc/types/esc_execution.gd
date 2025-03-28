## Class with enum containing the return codes returned by ASHES script functions.
extends Resource
class_name ESCExecution


## Return codes handled by events:[br]
##[br]
## * RC_OK: Event run okay.[br]
## * RC_CANCEL: Cancel all scheduled and queued events. This return code tells the Event Manager
## that no execution is required for this command (such as "stop" and "repeat").[br]
## * RC_ERROR: Error running a command.[br]
## * RC_REPEAT: Repeat the current scope from the beginning.[br]
## * RC_INTERRUPTED: Event was interrupted.[br]
## * RC_WONT_QUEUE: Event won't or can't be queued.
enum {RC_OK, RC_CANCEL, RC_ERROR, RC_REPEAT, RC_INTERRUPTED, RC_WONT_QUEUE}
