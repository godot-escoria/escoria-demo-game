# A compiled ESC script
extends Resource
class_name ESCScript


# A dictionary of ESCEvents in this script
var events: Dictionary


##############
# New interpreter stuff
var parsed_events = {}


# The name of the ESC file parsed for this script, if this script was in fact
# loaded from a file (as opposed to being from an internal string).
var filename: String = ""

##############
