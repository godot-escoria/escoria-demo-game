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


## Initializes the scope and sets the scope which encloses this one.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |enclosing|`Variant`|Optional parent environment used to resolve lookups outside this scope.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func init(enclosing) -> void:
	_enclosing = enclosing


func cleanup() -> void:
	if is_instance_valid(_enclosing):
		_enclosing.cleanup()
		_enclosing = null

	_values.clear()


## Determines whether the specified key (i.e. the script variable's name) is valid either within this scope or an enclosing scope.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |name|`ESCToken`|Token describing the variable name to look up.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns `true` if the variable exists in this scope or an enclosing scope, otherwise `false`. (`bool`)
func is_valid_key(name: ESCToken):
	if _values.has(name.get_lexeme()):
		return true

	if _enclosing:
		return _enclosing.is_valid_key(name)

	return false


## Fetches the value of the specified key (i.e. the script variable) from this scope or an enclosing one. otherwise, an error is produced[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |name|`ESCToken`|Token describing the variable name whose value is requested.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the value associated with the variable name, or produces an error if undefined. (`Variant`)
func get_value(name: ESCToken):
	if _values.has(name.get_lexeme()):
		return _values.get(name.get_lexeme())

	if _enclosing:
		return _enclosing.get_value(name)

	return _error(name, "Undefined variable '%s'." % name.get_lexeme())


## Assigns a value to the specified key (i.e. the script variable) from this scope or an enclosing one.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |name|`ESCToken`|Token describing the variable name to assign.|yes|[br]
## |value|`Variant`|the value to be assigned to the script variable|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing on success, or produces an error if the variable is undefined in all scopes.
func assign(name: ESCToken, value):
	if _values.has(name.get_lexeme()):
		_values[name.get_lexeme()] = value
		return

	if _enclosing:
		_enclosing.assign(name, value)
		return

	return _error(name, "Undefined variable '%s'." % name.get_lexeme())


## Defines a script variable in this scope and assigns it a value.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |name|`String`|Variable name to register in this scope.|yes|[br]
## |value|`Variant`|the value to be assigned to the script variable|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func define(name: String, value) -> void:
	_values[name] = value


## Fetches the scope (environment) that is `distance` levels up the enclosing scope chain.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |distance|`int`|The number of levels up the scope chain to traverse. `distance == 0` returns this scope (self); `distance == 1` returns the immediate enclosing scope; `distance == 2` returns the enclosing scope's enclosing scope, etc.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the environment (scope) at the specified distance up the enclosing scope chain. (`ESCEnvironment`)
func ancestor(distance: int):
	var env = self

	for i in range(0, distance):
		env = env.get_enclosing()

	return env


## Gets the value of the script variable (if it exists) that is at most `distance` levels above this one.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |distance|`int`|The number of scope levels to traverse; e.g. `distance == 0` is this scope, `distance == 1` is the enclosing scope, `distance == 2` is the enclosing scope's enclosing scope, etc.|yes|[br]
## |name|`String`|Variable name to resolve at the requested scope depth.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the value of the variable at the specified scope distance. (`Variant`)
func get_at(distance: int, name: String):
	return ancestor(distance).get_values().get(name)


## Assigns the specified value to the script variable (if it exists) that is at most `distance` levels above this one.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |distance|`int`|the number of scope levels to traverse; e.g. `distance == 0` is this scope, `distance == 1` is the enclosing scope, `distance == 2` is the enclosing scope's enclosing scope, etc.|yes|[br]
## |name|`ESCToken`|Token describing the variable name to modify at the requested scope depth.|yes|[br]
## |value|`Variant`|the value to assign to the script variable|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing. (`void`)
func assign_at(distance: int, name: ESCToken, value):
	ancestor(distance).get_values()[name.get_lexeme()] = value


func _to_string():
	var result: String = JSON.stringify(_values)

	if _enclosing:
		result += " -> %s" % JSON.stringify(_enclosing._to_string())

	return result


## The enclosing scope (environment) for this scope.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the enclosing scope (environment) for this scope. (`Variant`)
func get_enclosing():
	return _enclosing


## The dictionary storing all script variables and their associated values located at this scope's level.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the dictionary storing all script variables and their associated values located at this scope's level. (`Dictionary`)
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
