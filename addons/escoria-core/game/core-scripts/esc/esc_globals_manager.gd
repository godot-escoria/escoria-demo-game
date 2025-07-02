## A resource that manages the ASHES global states.
##
## The ASHES global state is basically simply a dictionary of keys with
## values. Values can be bool, integer or strings.
extends Resource
class_name ESCGlobalsManager


## Emitted when a global has changed.
signal global_changed(global, old_value, new_value)


# The globals registry.
@export var _globals: Dictionary = {}

## Registry of globals that are to be reserved for internal use only.
var _reserved_globals: Dictionary = {}

# Use look-ahead/behind to capture the term in braces
var _globals_regex: RegEx = RegEx.new()

## Constructor.
func _init():
	_globals_regex.compile("(?<=\\{)(.*)(?=\\})")


## Checks whether a global has already been registered.[br]
##[br]
## #### Parameters[br]
##[br]
## * key: The global key to check.[br]
##[br]
## **Returns** whether the global is registered.
func has(key: String) -> bool:
	return _globals.has(key)


## Clears all globals.
func clear() -> void:
	_globals.clear()
	if (escoria.inventory == null):
		escoria.logger.error(
			self,
			"The escoria.inventory property is null."
			+ "Please verify that the inventory scene (inheriting ESCInventory)"
			+ " main script's _ready() function calls super._ready()."
		)
	escoria.inventory.clear()


## Registers a global as being reserved and initializes it.[br]
## [br]
## #### Parameters[br]
## [br]
## - key: The key of the global to register.[br]
## - value: The initial value (optional).
func register_reserved_global(key: String, value = null) -> void:
	if key in _reserved_globals:
		escoria.logger.error(
			self,
			"Can not override reserved global: Global key %s is already " +
			"registered as reserved."
					% key
		)
	var old_value = _globals[key] if _globals.has(key) else ""
	_reserved_globals[key] = value
	_globals[key] = value

	if value != null:
		global_changed.emit(key, old_value, _globals[key])


## Retrieves the current value of a global.[br]
##[br]
## #### Parameters[br]
## [br]
## - key: The key of the global to return the value.[br]
## [br]
## **Returns** The value of the global.
func get_global(key: String):
	if _globals.has(key):
		return _globals[key]
	return null


## Filters the globals and return all matching keys and their values as
## a dictionary.[br]
##[br]
## Check out [the Godot docs](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-match)
## for the pattern format.[br]
##[br]
## #### Parameters[br]
## [br]
## - pattern: The pattern that the keys have to match.[br]
## [br]
## **Returns** A dictionary of matching keys and their values.
func filter(pattern: String) -> Dictionary:
	var ret = {}
	for global_key in _globals.keys():
		if global_key.match(pattern):
			ret[global_key] = _globals[global_key]
	return ret


## Sets the value of a global.[br]
##[br]
## #### Parameters[br]
## * key: The key of the global to modify.[br]
## * value: The new value to be stored with the key.
func set_global(key: String, value, ignore_reserved: bool = false) -> void:
	if key in _reserved_globals and not ignore_reserved:
		escoria.logger.error(
			self,
			"Global key %s is reserved and can not be overridden." % key
		)

	global_changed.emit(
		key,
		_globals[key] if _globals.has(key) else null,
		value
	)
	_globals[key] = value


## Sets all globals that match the pattern to the value.[br]
##[br]
## Check out [the Godot docs](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-match)
## for the pattern format.[br]
##[br]
## #### Parameters[br]
## * pattern: The wildcard pattern to match.[br]
## * value: The new value to be stored with the key.
func set_global_wildcard(pattern: String, value) -> void:
	for global_key in _globals.keys:
		if global_key.match(pattern):
			self.set_global(global_key, value)


## Replaces any globals whose names are specified in braces with their respective 
## values (i.e. performs string interpolation).[br]
##[br]
## #### Parameters[br]
## * string: The text in which globals in braces are to be substituted.
##[br]
## **Returns** the provided string with globals variables replaced using their respective 
## values.
func replace_globals(string: String) -> String:
	for result in _globals_regex.search_all(string):
		var globresult = escoria.globals_manager.get_global(
			str(result.get_string())
		)
		string = string.replace(
			"{" + result.get_string() + "}", str(globresult)
		)
	return string


## Saves the state of globals in the savegame.[br]
##[br]
## #### Parameters[br]
## * p_savegame: `ESCSaveGame` resource that holds all save data.
func save_game(p_savegame: ESCSaveGame) -> void:
	p_savegame.globals = {}
	for g in _globals:
		if not g.begins_with("i/"):
			p_savegame.globals[g] = _globals[g]
