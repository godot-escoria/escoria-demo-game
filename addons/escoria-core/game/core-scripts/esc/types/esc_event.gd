## An event in Escoria.
##
## Events are triggered from various sources. Common events include:[br]
##[br]
## - `:setup` : This event is always the first to be called each time the room is visited.
##    It allows elements in the room to be prepared *before* the room is displayed to the
##    player (e.g. starting particle effects).[br]
## - `:ready` : This event is the second to be called each time the room is visited.
##    It is run immediately after `:setup` finishes execution, if it exists. Otherwise,
##    `:ready` will be the first event to run. Regardless, this event is run *after*
##    the room is displayed to the player, allowing cutscenes or animations to be
##    run once the room is visible.[br]
## - `:use <global id>` : Called from the current item when it is used with the item
##   with specified by `<global id>`.
extends ESCStatement
class_name ESCEvent


# Regex identifying an ESC event
const REGEX = \
	'^:(?<name>[^|]+)( \\|\\s*(?<flags>( ' + \
	'(TK|NO_TT|NO_UI|NO_SAVE)' + \
	')+))?$'

# Prefix to identify this as an ESC event.
const PREFIX = ":"


## Valid event flags:[br]
## - `TK`: stands for "telekinetic". It means the player won't walk over to
##   the item to say the line.[br]
## - `NO_TT`: stands for "No tooltip". It hides the tooltip for the duration of
##   the event. Probably not very useful, because events having multiple
##   say commands in them are automatically hidden.[br]
## - `NO_UI`: stands for "No User Inteface". It hides the UI for the duration of
##   the event. Useful when you want something to look like a cut scene but not
##   disable input for skipping dialog.[br]
## - `NO_SAVE`: disables saving. Use this in cut scenes and anywhere a
##   badly-timed autosave would leave your game in a messed-up state.
enum FLAGS {
	TK = 1,
	NO_TT = 2,
	NO_UI = 4,
	NO_SAVE = 8
}


## Name of the event.
var name: String

## Original name of the event (in case it is modified when resuming a loaded event).
var original_name: String

## Flags set for this event.
var flags: int = 0


## Returns a Dictionary containing statements data for serialization, typically 
## used as part of the savegame process.
func exported() -> Dictionary:
	var exported_dict: Dictionary = super.exported()
	exported_dict.class = "ESCEvent"
	exported_dict.name = name
	exported_dict.original_name = original_name
	exported_dict.flags = flags

	return exported_dict


## Initializes the event with specified arguments.[br]
##[br]
## #### Parameters ####
## *event_name*: the name of the event[br]
## *event_flags*: an array containing zero or more event flags as described in 
## the enum contained in this class.
func init(event_name: String, event_flags: Array) -> void:
	name = event_name
	flags = get_flags_from_list(event_flags)


static func get_flags_from_list(event_flags: Array[String]) -> int:
	var computed_flags: int = 0
	for flag in event_flags:
		match flag:
			"TK":
				computed_flags |= FLAGS.TK
			"NO_TT":
				computed_flags |= FLAGS.NO_TT
			"NO_UI":
				computed_flags |= FLAGS.NO_UI
			"NO_SAVE":
				computed_flags |= FLAGS.NO_SAVE
	return computed_flags


## Executes this statement and returns a return code.
func run() -> int:
	reset_interrupt()
	escoria.logger.debug(
		self,
		"Event %s started." % name
	)
	if name == "resume":
		bypass_conditions = true
	return await super()


## Returns the event's name.
func get_event_name() -> String:
	return name
