## A single option used as part of a dialog.
##
## `ESCDialog` makes use of these when assembling an actual dialog in Escoria.
extends ESCStatement
class_name ESCDialogOption


## Option text displayed in the HUD.
var option: String:
	get = get_translated_option

## Maps back to the parsed source option.
var source_option

## Whether this option is valid.
var _is_valid: bool:
	set = set_is_valid,
	get = is_valid


## Returns the translated version of the option, if one exists; otherwise, the 
## default text is returned.
func get_translated_option() -> String:
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


## Returns whether this dialog option is valid. Note: this value isn't currently 
## used as part of any meaningful validation checks.
func is_valid() -> bool:
	return _is_valid


## Sets whether the option is valid, although this value isn't currently used 
## as part of any useful checks.
func set_is_valid(value: bool) -> void:
	_is_valid = value
