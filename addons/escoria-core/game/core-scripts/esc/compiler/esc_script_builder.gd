## Convenience class to help build scripts in code for use with the ASHES compiler 
## toolchain. Loosely follows the Builder pattern.
extends RefCounted
class_name ESCScriptBuilder


# Not really a "Builder" pattern per se, but helps with readability.


var _script: String = ""
var _indent_level: int = 0


## Returns the script as it currently exists. No building is actually performed 
## and therefore no error checking of any kind is performed.
func build():
	return _script


## Adds an Escoria event to the script.[br]
##[br]
## #### Parameters ####[br]
## - *name*: the name of the event, without any prefixes; e.g. `look`[br]
## - *flags*: an array of flags for the event, e.g. `TK`
func add_event(name: String, flags: Array):
	_script += ":" + name

	if flags:
		_script += " | "
		_script += " ".join(flags)

	_script += "\n"

	return self


## Begins a new block/scope for the script.
func begin_block():
	_indent_level += 1

	return self


## Closes the current block/scope of the script.
func end_block():
	_indent_level -= 1

	return self


## Adds a command to be called in the script.[br]
##[br]
## #### Parameters ####[br]
## - *name*: the name of the command to be called[br]
## - *args*: the arguments for the command; can be a single argument or an array
func add_command(name: String, args):
	if not args is Array:
		args = [args]

	_script += "\t".repeat(_indent_level)
	_script += name

	_script += "("

	var args_string: String = ""

	for arg in args:
		if !args_string.is_empty():
			args_string += ", "

		if arg is String:
			args_string += "\"" + arg + "\""
		else:
			args_string += str(arg)

	_script += args_string + ")"

	_script += "\n"

	return self
