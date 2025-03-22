# An option of an ESC dialog
extends ESCStatement
class_name ESCDialogOption


# Option displayed in the HUD
var option: String:
	get = get_translated_option

# Maps back to the parsed source option.
var source_option

var _is_valid: bool:
	set = set_is_valid,
	get = is_valid


func get_translated_option():
	# Check if text has a key
	if ":" in option:
		var splitted_text = option.split(":")
		var key = splitted_text[0]
		var translated_text = tr(key)

		# If no translation is found use default text
		if key != translated_text:
			return tr(key)
		if splitted_text.size() > 1:
			return splitted_text[1]

	return option


# Check, if conditions match
func is_valid() -> bool:
	return _is_valid


func set_is_valid(value: bool) -> void:
	_is_valid = value
