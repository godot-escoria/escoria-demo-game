# An option of an ESC dialog
extends ESCStatement
class_name ESCDialogOption


# Regex that matches dialog option lines
const REGEX = \
	'^[^-]*- (?<trans_key>[^:]+)?:?"' +\
	'(?<option>[^"]+)"( \\[(?<conditions>[^\\]]+)\\])?$'


# Option displayed in the HUD
var option: String setget ,get_option

# Conditions to show this dialog
var conditions: Array = []


# Create a dialog option from an ESC string
#
# #### Parameter
# - option_string: ESC string for the dialog option
func load_string(option_string: String):
	var option_regex = RegEx.new()
	option_regex.compile(REGEX)
	
	if option_regex.search(option_string):
		for result in option_regex.search_all(option_string):
			if "option" in result.names:
				var _trans_key = ""
				if "trans_key" in result.names:
					_trans_key = "%s:" % \
							escoria.utils.get_re_group(result, "trans_key")
				self.option = "%s%s" % [
					_trans_key,
					escoria.utils.get_re_group(result, "option")
				]
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


func get_option():
	if ":" in option:
		return tr(option.split(":")[0])
	return option


# Check, if conditions match
func is_valid() -> bool:
	for condition in self.conditions:
		if not (condition as ESCCondition).run():
			return false
	return true
