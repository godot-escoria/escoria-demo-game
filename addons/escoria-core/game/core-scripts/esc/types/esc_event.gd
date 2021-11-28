# An event in the ESC language
#
# Events are triggered from various sources. Common events include
#
# * :setup Called every time when visiting a scene
# * :ready Called the first time a scene is visited
# * :use <global id> Called from the current item when it is used with the item
#   with the global id <global id>
extends ESCStatement
class_name ESCEvent


# Regex identifying an ESC event
const REGEX = \
	'^:(?<name>[^|]+)( \\|\\s*(?<flags>( ' + \
	'(TK|NO_TT|NO_UI|NO_SAVE)' + \
	')+))?$'


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

# Flags set to this event
var flags: int = 0


# Create a new event from an event line
func _init(event_string: String):
	var event_regex = RegEx.new()
	event_regex.compile(REGEX)
	
	if event_regex.search(event_string):
		for result in event_regex.search_all(event_string):
			if "name" in result.names:
				self.name = escoria.utils.get_re_group(result, "name") \
					.strip_edges()
			if "flags" in result.names:
				var _flags = escoria.utils.get_re_group(
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
		escoria.logger.report_errors(
			"Invalid event detected: %s" % event_string,
			[
				"Event regexp didn't match"
			]
		)


# Execute this statement and return its return code
func run() -> int:
	reset_interrupt()
	escoria.logger.debug("Event %s started" % name)
	return .run()
