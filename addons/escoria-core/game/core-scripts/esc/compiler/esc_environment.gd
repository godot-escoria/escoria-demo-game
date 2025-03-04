## Class to track variables and their associated scopes within a script.
##
## Scoping is implemented using this class, including traditional scoping rules. 
## Scope binding and resolution are handled in this class.
extends Object
class_name ESCEnvironment


var _enclosing: # ESCEnvironment
	get = get_enclosing
var _values: Dictionary = {}:
	get = get_values


## Initializes the scope and sets the scope which encloses this one.
func init(enclosing) -> void:
	_enclosing = enclosing


## Determines whether the specified key (i.e. the script variable's name) is valid 
## either within this scope or an enclosing scope.[br]
##[br]
## #### Parameters ####[br]
## - name: the script variable to look up; must be a valid `ESCToken`[br]
##[br]
## *Returns* true iff `name` is defined within this scope or an enclosing one
func is_valid_key(name: ESCToken):
	if _values.has(name.get_lexeme()):
		return true

	if _enclosing:
		return _enclosing.is_valid_key(name)

	return false


## Fetches the value of the specified key (i.e. the script variable) from this 
## scope or an enclosing one.[br]
##[br]
## #### Parameters ####[br]
## - name: the script variable to look up; must be a valid `ESCToken`[br]
##[br]
## *Returns* the value if `name` is defined within this scope or an enclosing one; 
## otherwise, an error is produced
func get_value(name: ESCToken):
	if _values.has(name.get_lexeme()):
		return _values.get(name.get_lexeme())

	if _enclosing:
		return _enclosing.get_value(name)

	return _error(name, "Undefined variable '%s'." % name.get_lexeme())


## Assigns a value to the specified key (i.e. the scipt variable) from this 
## scope or an enclosing one.[br]
##[br]
## #### Parameters ####[br]
## - name: the script variable to look up; must be a valid `ESCToken`[br]
## - value: the value to be assigned to the script variable
##[br]
## *Returns* an error if `name` isn't defined within this scope or an enclosing one
func assign(name: ESCToken, value):
	if _values.has(name.get_lexeme()):
		_values[name.get_lexeme()] = value
		return

	if _enclosing:
		_enclosing.assign(name, value)
		return

	return _error(name, "Undefined variable '%s'." % name.get_lexeme())


## Defines a script variable in this scope and assigns it a value.[br]
##[br]
## #### Parameters ####[br]
## - name: the script variable to look up; must be a valid `ESCToken`[br]
## - value: the value to be assigned to the script variable
func define(name: String, value) -> void:
	_values[name] = value


## Fetches the enclosing scope (environment) of the environment that is `distance`
## levels above this one, if it exists.[br]
##[br]
## #### Parameters ####[br]
## - distance: the number of levels above this one from which to fetch the 
## associated environment; e.g. `distance == 2` is the enclosing scope's own 
## enclosing scope; `distance == 0` is this scope's enclosing scope, etc.[br]
##[br]
## *Returns* the enclosing scope (environment) of the environment that is `distance` 
## levels above this one.
func ancestor(distance: int):
	var env = self

	for i in range(0, distance):
		env = env.get_enclosing()

	return env


## Gets the value of the script variable (if it exists) that is at most `distance` 
## levels above this one.[br]
##[br]
## #### Parameters ####
## - distance: the number of levels above this one from which to fetch the 
## associated environment; e.g. `distance == 2` is the enclosing scope's own 
## enclosing scope; `distance == 0` is this scope's enclosing scope, etc.[br]
## - name: the script variable to look up; note that this must be a String[br]
##[br]
## *Returns* the value associated with the script variable, if it exists
func get_at(distance: int, name: String):
	return ancestor(distance).get_values().get(name)


## Assigns the specified value to the script variable (if it exists) that is at 
## most `distance` levels above this one.[br]
##[br]
## #### Parameters ####
## - distance: the number of levels above this one from which to fetch the 
## associated environment; e.g. `distance == 2` is the enclosing scope's own 
## enclosing scope; `distance == 0` is this scope's enclosing scope, etc.[br]
## - name: the script variable to look up; must be a valid `ESCToken`[br]
## - value: the value to assign to the script variable
func assign_at(distance: int, name: ESCToken, value):
	ancestor(distance).get_values()[name.get_lexeme()] = value


func _to_string():
	var result: String = JSON.stringify(_values)

	if _enclosing:
		result += " -> %s" % JSON.stringify(_enclosing._to_string())

	return result


## Returns the closing scope (environment) for this scope.
func get_enclosing():
	return _enclosing


## Returns the dictionary storing all script variables and their associated values
## located at this scope's level.
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
