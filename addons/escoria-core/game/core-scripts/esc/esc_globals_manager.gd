# A resource that manages the ESC global states
# The ESC global state is basically simply a dictionary of keys with
# values. Values can be bool, integer or strings
extends Resource
class_name ESCGlobalsManager


# Emitted when a global is changed
signal global_changed(global, old_value, new_value)


# A list of reserved globals which can not be overridden
const RESERVED_GLOBALS = [
	"ESC_LAST_SCENE"
]


# The globals registry
export(Dictionary) var _globals = {}



func _init():
	set_global("ESC_LAST_SCENE", "", true)


# Check if a global was registered
#
# #### Parameters
#
# - key: The global key to check
# **Returns** Wether the global was registered
func has(key: String) -> bool:
	return _globals.has(key)


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
	if key in RESERVED_GLOBALS and not ignore_reserved:
		escoria.logger.report_errors(
			"ESCGlobalsManager.set_global: Can not override reserved global",
			[
				"Global key %s is reserved and can not be overridden" % key
			]
		)
	_globals[key] = value
	emit_signal("global_changed", key, _globals[key], value)
	
	
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
