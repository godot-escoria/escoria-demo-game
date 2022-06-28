# A set of common utilities
extends Reference
class_name ESCUtils


# Convert radians to degrees
#
# #### Parameters
#
# - rad_angle: Angle in radians
# **Returns** Degrees
static func get_deg_from_rad(rad_angle: float):
	var deg = rad2deg(rad_angle)
	if deg >= 360.0:
		deg = clamp(deg, 0.0, 360.0)
		if deg == 360.0:
			deg = 0.0
	return deg


# Get the content of a reg exp group by name
#
# #### Parameters
#
# - re_match: The RegExMatch object
# - group: The name of the group
# **Returns** The value of the named regex group in the match
static func get_re_group(re_match: RegExMatch, group: String) -> String:
	if group in re_match.names:
		return re_match.strings[re_match.names[group]]
	else:
		return ""


# Return a string value in the correct infered type
#
# #### Parameters
#
# - value: The original value
# - type_hint: The type it should be
# **Returns** The typed value according to the type inference
static func get_typed_value(value: String, type_hint = []):
	var regex_bool = RegEx.new()
	regex_bool.compile("^true|false$")
	var regex_float = RegEx.new()
	regex_float.compile("^-?[0-9]*\\.[0-9]+$")
	var regex_int = RegEx.new()
	regex_int.compile("^-?[0-9]+$")

	if regex_float.search(value):
		return float(value)
	elif regex_int.search(value):
		return int(value)
	elif regex_bool.search(value.to_lower()):
		return true if value.to_lower() == "true" else false
	elif (typeof(type_hint) != TYPE_ARRAY and type_hint == TYPE_ARRAY) or \
			(typeof(type_hint) == TYPE_ARRAY and TYPE_ARRAY in type_hint) \
			and "," in value:
		return value.split(",")
	else:
		return str(value)


# Sanitize use of whitespaces in a string. Removes double whitespaces
# and converts tabs into space.
#
# #### Paramters
#
# - value: String to work on
# **Returns** the string with sanitized whitespaces
static func sanitize_whitespace(value: String) -> String:
	var tab_regex = RegEx.new()
	tab_regex.compile("\\t")
	var double_regex = RegEx.new()
	double_regex.compile("\\s\\s+")
	return double_regex.sub(
		tab_regex.sub(value, " "),
		" ",
		true
	)
