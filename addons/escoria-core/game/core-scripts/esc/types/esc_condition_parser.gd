extends Object
class_name ESCConditionParser


# Regex that matches condition lines
const REGEX = \
	'^(?<is_negated>!)?(?<comparison>eq|gt|lt)? ?(?<is_inventory>i\/)?' + \
	'(?<is_activity>a\/)?(?<flag>[^ ]+)( (?<comparison_value>.+))?$'


static func parse(comparison_string: String) -> ESCCondition:
	var comparison_regex = RegEx.new()
	comparison_regex.compile(
		REGEX
	)

	var flag = ""
	var negated = false
	var inventory = false
	var comparison = ESCCondition.COMPARISON_NONE
	var comparison_value = null

	if comparison_regex.search(comparison_string):
		for result in comparison_regex.search_all(comparison_string):
			if "is_negated" in result.names:
				negated = true
			if "comparison" in result.names:
				match ESCUtils.get_re_group(result, "comparison"):
					"eq": comparison = ESCCondition.COMPARISON_EQ
					"gt": comparison = ESCCondition.COMPARISON_GT
					"lt": comparison = ESCCondition.COMPARISON_LT
					_:
						escoria.logger.error(
							{},
							"Invalid comparison type detected: %s" %
									comparison_string +
							"Comparison type %s unknown" %
									ESCUtils.get_re_group(
										result,
										"comparison"
									)
						)
			if "comparison_value" in result.names:
				comparison_value = ESCUtils.get_typed_value(
					ESCUtils.get_re_group(
						result,
						"comparison_value"
					)
				)
			if "is_inventory" in result.names:
				inventory = true
			if "is_activity" in result.names:
				comparison = ESCCondition.COMPARISON_ACTIVITY
			if "flag" in result.names:
				flag = ESCUtils.get_re_group(result, "flag")
	else:
		escoria.logger.error(
			{},
			"Invalid comparison detected: %s\nComparison regexp didn't match."
					% comparison_string
		)

	return ESCCondition.new(flag, comparison_value, negated, inventory, comparison)
