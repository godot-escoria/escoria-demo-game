## A set of common utilities.
extends RefCounted
class_name ESCUtils

## Convert radians to degrees.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |rad_angle|`float`|Angle in radians.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
static func get_deg_from_rad(rad_angle: float):
	var deg = rad_to_deg(rad_angle)
	if deg >= 360.0:
		deg = clamp(deg, 0.0, 360.0)
		if deg == 360.0:
			deg = 0.0
	return deg

## Get the content of a reg exp group by name.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |re_match|`RegExMatch`|The RegExMatch object.|yes|[br]
## |group|`String`|The name of the group.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `String` value. (`String`)
static func get_re_group(re_match: RegExMatch, group: String) -> String:
	if group in re_match.names:
		return re_match.strings[re_match.names[group]]
	else:
		return ""

## Return a string value in the correct inferred type.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |value|`String`|The original value.|yes|[br]
## |type_hint|`Variant`|The type it should be.|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
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

## Sanitize use of whitespaces in a string. Removes double whitespaces and converts tabs into space.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |value|`String`|String to work on.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `String` value. (`String`)
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
