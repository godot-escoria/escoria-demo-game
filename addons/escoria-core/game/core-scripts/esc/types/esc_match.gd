extends ESCStatement
class_name ESCMatch


# A RegEx identifying a match block
const REGEX = '^([^>]*)>>\\s*(?<expr>.+)$'

const MATCH_ARM_REGEX = '^\\s*(?<cond_expr>.+)\\s+=>\\s*$'

# The expression to match.
var expr: String

# An array of arrays where each entry is a tuple of (ESCCondition, ESCStatement).
var _match_conditions: Array


func _init(match_string: String) -> void:
	var match_regex = RegEx.new()
	match_regex.compile(REGEX)

	var match_regex_result = match_regex.search(match_string)
	if match_regex_result:
		self.expr = escoria.utils.get_re_group(match_regex_result, "expr")
	else:
		escoria.logger.report_errors(
			"Invalid match statement detected: %s" % match_string,
			[
				"Match statement regexp didn't match"
			]
		)


func is_valid() -> bool:
	return true


func add_arm(cond: ESCCondition, stmt: ESCStatement) -> void:
	_match_conditions.append([cond, stmt])


func run() -> int:
	# Must ensure that at most one condition is satisfied.
	for pair in _match_conditions:
		var condition = pair[0]
		if condition.run():
			var statement = pair[1]
			return statement.run()
	return ESCExecution.RC_OK


func parse(lines: Array) -> Array:
	var arm_regex = RegEx.new()
	arm_regex.compile(MATCH_ARM_REGEX)

	var branches = []
	for line in lines:
		var arm_result = arm_regex.search(line)
		if arm_result:
			var cond_expr = escoria.utils.get_re_group(arm_result, "cond_expr")
			escoria.logger.trace("found match arm '%s'" % cond_expr)
			var cond = null
			if cond_expr == '_':
				# TODO: const ESCCondition.
				cond = ESCCondition.new("eq 1 1")
			else:
				cond = ESCCondition.new("eq %s %s" % [self.expr, cond_expr])
			var pair = [cond, []]
			branches.append(pair)
		else:
			# There should be an existing pair in branches...
			var latest_pair = branches[branches.size() - 1]
			latest_pair[1].append(line)

	return branches
