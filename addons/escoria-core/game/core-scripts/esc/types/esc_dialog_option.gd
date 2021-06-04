# An option of an ESC dialog
extends ESCStatement
class_name ESCDialogOption


# Regex that matches dialog option lines
const REGEX = \
	'^[^-]*- "(?<option>[^"]+)"( \\[(?<conditions>[^\\]]+)\\])?$'


# Option displayed in the HUD
var option: String

# Conditions to show this dialog
var conditions: Array = []


# Create a dialog option from a string
func _init(option_string: String):
	var option_regex = RegEx.new()
	option_regex.compile(REGEX)
	
	if option_regex.search(option_string):
		for result in option_regex.search_all(option_string):
			if "option" in result.names:
				self.option = escoria.utils.get_re_group(result, "option")
			if "conditions" in result.names:
				for condition_text in escoria.utils.get_re_group(
							result, 
							"conditions"
						).split(","):
					self.conditions.append(
						ESCCondition.new(condition_text.strip_edges())
					)
	else:
		escoria.logger.report_errors(
			"Invalid dialog option detected: %s" % option_string,
			[
				"Dialog option regexp didn't match"
			]
		)


# Check, if conditions match
func is_valid() -> bool:
	for condition in self.conditions:
		if not (condition as ESCCondition).run():
			return false
	return true
