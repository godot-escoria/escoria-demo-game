extends Reference
class_name ESCScriptBuilder


# Not really a "Builder" pattern per se, but helps with readability.


var _script: String = ""
var _indent_level: int = 0


func build():
	return _script


func add_event(name: String, flags: Array):
	_script += ":" + name

	if flags:
		_script += " | "
		_script += " ".join(flags)

	_script += "\n"

	return self


func begin_block():
	_indent_level += 1

	return self


func end_block():
	_indent_level -= 1

	return self


func add_command(name: String, args):
	if not args is Array:
		args = [args]

	_script += "\t".repeat(_indent_level)
	_script += name

	_script += "("

	var args_string: String = ""

	for arg in args:
		if !args_string.empty():
			args_string += ", "

		if arg is String:
			args_string += "\"" + arg + "\""
		else:
			args_string += str(arg)

	_script += args_string + ")"

	_script += "\n"

	return self
