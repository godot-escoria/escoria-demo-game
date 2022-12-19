# An event in the ESC language
#
# Events are triggered from various sources. Common events include
#
# * :setup : This event is always the first to be called each time the room is visited.
#    It allows elements in the room to be prepared *before* the room is displayed to the
#    player (e.g. starting particle effects).
# * :ready : This event is the second to be called each time the room is visited.
#    It is run immediately after `:setup` finishes execution, if it exists. Otherwise,
#    `:ready` will be the first event to run. Regardless, this event is run *after*
#    the room is displayed to the player, allowing cutscenes or animations to be
#    run once the room is visible.
# * :use <global id> Called from the current item when it is used with the item
#   with the global id <global id>
extends ESCStatement
class_name ESCEvent


# Regex identifying an ESC event
const REGEX = \
	'^:(?<name>[^|]+)( \\|\\s*(?<flags>( ' + \
	'(TK|NO_TT|NO_UI|NO_SAVE)' + \
	')+))?$'

# Prefix to identify this as an ESC event.
const PREFIX = ":"


# Valid event flags
# * TK: stands for "telekinetic". It means the player won't walk over to
#   the item to say the line.
# * NO_TT: stands for "No tooltip". It hides the tooltip for the duration of
#   the event. Probably not very useful, because events having multiple
#   say commands in them are automatically hidden.
# * NO_UI: stands for "No User Inteface". It hides the UI for the duration of
#   the event. Useful when you want something to look like a cut scene but not
#   disable input for skipping dialog.
# * NO_SAVE: disables saving. Use this in cut scenes and anywhere a
#   badly-timed autosave would leave your game in a messed-up state.
enum {
	FLAG_TK = 1,
	FLAG_NO_TT = 2,
	FLAG_NO_UI = 4,
	FLAG_NO_SAVE = 8
}


# Name of event
var name: String

# Original name of the event (in case it is modified when resuming a loaded event)
var original_name: String

# Flags set to this event
var flags: int = 0

# Returns a Dictionary containing statements data for serialization
func exported() -> Dictionary:
	var exported_dict: Dictionary = .exported()
	exported_dict.class = "ESCEvent"
	exported_dict.name = name
	exported_dict.original_name = original_name
	exported_dict.flags = flags
	return exported_dict


# Create a new event from an event line
func _init(event_string: String):
	var event_regex = RegEx.new()
	event_regex.compile(REGEX)

	if event_regex.search(event_string):
		for result in event_regex.search_all(event_string):
			if "name" in result.names:
				self.name = ESCUtils.get_re_group(result, "name") \
					.strip_edges()
				self.original_name = self.name
			if "flags" in result.names:
				var _flags = ESCUtils.get_re_group(
						result,
						"flags"
					).strip_edges().split(" ")
				if "TK" in _flags:
					self.flags |= FLAG_TK
				if "NO_TT" in _flags:
					self.flags |= FLAG_NO_TT
				if "NO_UI" in _flags:
					self.flags |= FLAG_NO_UI
				if "NO_SAVE" in _flags:
					self.flags |= FLAG_NO_SAVE
	else:
		escoria.logger.warn(
			self,
			"Invalid event detected: %s\nEvent regexp didn't match."
					% event_string
		)


func init(event_name: String, event_flags: Array):
	name = event_name

	for flag in event_flags:
		match flag:
			"TK":
				flags |= FLAG_TK
			"NO_TT":
				flags |= FLAG_NO_TT
			"NO_UI":
				flags |= FLAG_NO_UI
			"NO_SAVE":
				flags |= FLAG_NO_SAVE


# Execute this statement and return its return code
func run() -> int:
	reset_interrupt()
	escoria.logger.debug(
		self,
		"Event %s started." % name
	)
	if name == "resume":
		bypass_conditions = true
	return .run()


func get_event_name() -> String:
	return name
