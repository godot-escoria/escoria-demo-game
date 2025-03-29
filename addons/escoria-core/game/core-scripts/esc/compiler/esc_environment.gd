extends Object
class_name ESCEnvironment


var _enclosing: # ESCEnvironment
	get = get_enclosing
var _values: Dictionary = {}:
	get = get_values


func init(enclosing) -> void:
	_enclosing = enclosing


func is_valid_key(name: ESCToken):
	if _values.has(name.get_lexeme()):
		return true

	if _enclosing:
		return _enclosing.is_valid_key(name)

	return false


func get_value(name: ESCToken):
	if _values.has(name.get_lexeme()):
		return _values.get(name.get_lexeme())

	if _enclosing:
		return _enclosing.get_value(name)

	return _error(name, "Undefined variable '%s'." % name.get_lexeme())


func assign(name: ESCToken, value):
	if _values.has(name.get_lexeme()):
		_values[name.get_lexeme()] = value
		return

	if _enclosing:
		_enclosing.assign(name, value)
		return

	return _error(name, "Undefined variable '%s'." % name.get_lexeme())


func define(name: String, value) -> void:
	_values[name] = value


# Binding with resolution code
func ancestor(distance: int):
	var env = self

	for i in range(0, distance):
		env = env.get_enclosing()

	return env


func get_at(distance: int, name: String):
	return ancestor(distance).get_values().get(name)


func assign_at(distance: int, name: ESCToken, value):
	ancestor(distance).get_values()[name.get_lexeme()] = value


func _to_string():
	var result: String = JSON.stringify(_values)

	if _enclosing:
		result += " -> %s" % JSON.stringify(_enclosing._to_string())

	return result


func get_enclosing():
	return _enclosing


func get_values():
	return _values


func _error(token: ESCToken, message: String):
	var source: String = token.get_filename() if not token.get_filename().is_empty() else token.get_source()
	ESCSafeLogging.log_error(
		self,
		"%s: Line %s at '%s': %s" % [source, token.get_line(), token.get_lexeme(), message]
	)


func _warn(token: ESCToken, message: String):
	var source: String = token.get_filename() if not token.get_filename().is_empty() else token.get_source()
	escoria.logger.warn(
		self,
		"%s: Line %s at '%s': %s" % [source, token.get_line(), token.get_lexeme(), message]
	)
