# A resource that manages the ESC global states
# The ESC global state is basically simply a dictionary of keys with
# values. Values can be bool, integer or strings
extends Resource
class_name ESCGlobalsManager


# Emitted when a global is changed
signal global_changed(global, old_value, new_value)


# The globals registry
export(Dictionary) var _globals = {}


# Registry of globals that are to be reserved for internal use only.
var _reserved_globals: Dictionary = {}

# Use look-ahead/behind to capture the term in braces
var globals_regex: RegEx = RegEx.new()

# Constructor
func _init():
	globals_regex.compile("(?<=\\{)(.*)(?=\\})")


# Check if a global was registered
#
# #### Parameters
#
# - key: The global key to check
# **Returns** Whether the global was registered
func has(key: String) -> bool:
	return _globals.has(key)


# Clear all globals.
func clear():
	_globals.clear()
	escoria.inventory.clear()


# Registers a global as being reserved and initializes it.
#
# #### Parameters
#
# - key: The key of the global to register
# - value: The initial value (optional)
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
		emit_signal("global_changed", key, old_value, _globals[key])


# Get the current value of a global
#
# #### Parameters
#
# - key: The key of the global to return the value
# **Returns** The value of the global
func get_global(key: String):
	if _globals.has(key):
		return _globals[key]
	return null


# Filter the globals and return all matching keys and their values as
# a dictionary
# Check out [the Godot docs](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-match)
# for the pattern format
#
# #### Parameters
#
# - pattern: The pattern that the keys have to match
# **Returns** A dictionary of matching keys and their values
func filter(pattern: String) -> Dictionary:
	var ret = {}
	for global_key in _globals.keys():
		if global_key.match(pattern):
			ret[global_key] = _globals[global_key]
	return ret


# Set the value of a global
#
# #### Parameters
#
# - key: The key of the global to modify
# - value: The new value
func set_global(key: String, value, ignore_reserved: bool = false) -> void:
	if key in _reserved_globals and not ignore_reserved:
		escoria.logger.error(
			self,
			"Global key %s is reserved and can not be overridden." % key
		)

	emit_signal(
		"global_changed",
		key,
		_globals[key] if _globals.has(key) else null,
		value
	)
	_globals[key] = value


# Set all globals that match the pattern to the value
# Check out [the Godot docs](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-match)
# for the pattern format
#
# #### Parameters
#
# - pattern: The wildcard pattern to match
# - value: The new value
func set_global_wildcard(pattern: String, value) -> void:
	for global_key in _globals.keys:
		if global_key.match(pattern):
			self.set_global(global_key, value)


# Look to see if any globals (names in braces) should be interpreted
#
# #### Parameters
#
# * string: Text in which to replace globals
#
# *Returns* the provided string with globals variables replaced with their values
func replace_globals(string: String) -> String:
	for result in globals_regex.search_all(string):
		var globresult = escoria.globals_manager.get_global(
			str(result.get_string())
		)
		string = string.replace(
			"{" + result.get_string() + "}", str(globresult)
		)
	return string


# Save the state of globals in the savegame.
#
# #### Parameters
# - p_savegame: ESCSaveGame resource that holds all data of the save
func save_game(p_savegame: ESCSaveGame) -> void:
	p_savegame.globals = {}
	for g in _globals:
		if not g.begins_with("i/"):
			p_savegame.globals[g] = _globals[g]

