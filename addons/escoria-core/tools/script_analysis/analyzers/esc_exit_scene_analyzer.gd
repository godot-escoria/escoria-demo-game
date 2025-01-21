extends ESCScriptAnalyzer
class_name ESCExitSceneScriptAnalyzer


const EXIT_SCENE_EVENT_NAME = "exit_scene"
const ACCEPT_INPUT_DISABLE_ARGS = ["none", "skip"]
const ACCEPT_INPUT_ENABLE_ARG = "all"

const CHANGE_SCENE_MISSING_MESSAGE = "Event ':exit_scene' is missing 'change_scene' command. Scene might not change as expected."

const MISSING_ACCEPT_INPUT_MESSAGE = \
	"Event ':exit_scene' may allow for the player character to move while exiting and changing the scene." \
	+ " To prevent this, ensure a call to 'accept_input' with an argument evaluating to 'NONE' or 'SKIP' is" \
	+ " made before any calls to 'transition' and/or 'change_scene', and a call to 'accept_input' with an argument evaluating to 'ALL' exists after those calls."


# These are vars because they have to be, but should be treated as consts
var TRANSITION_COMMAND_NAME = TransitionCommand.new().get_command_name()
var CHANGE_SCENE_COMMAND_NAME = ChangeSceneCommand.new().get_command_name()
var ACCEPT_INPUT_COMMAND_NAME = AcceptInputCommand.new().get_command_name()


# Returns: Array of strings for any issues detected.
func analyze(statements: Array) -> void:
	var issue_messages: Array[String] = []

	for statement in statements:
		if statement.get_event_name().to_lower() == EXIT_SCENE_EVENT_NAME:
			issue_messages = _analyze_exit_scene_event(statement)
			break

	for message in issue_messages:
		ESCSafeLogging.log_warn(self, message)


func _analyze_exit_scene_event(event) -> Array[String]:
	var issue_messages: Array[String] = []

	if not _check_for_change_scene_command(event):
		issue_messages.push_back(CHANGE_SCENE_MISSING_MESSAGE)

	if _allows_undesired_player_movement(event):
		issue_messages.push_back(MISSING_ACCEPT_INPUT_MESSAGE)

	return issue_messages


# Check to see if the player is still able to move in the case where either:
# - `transition()`, or,
# - `change_scene()` with the `enable_automatic_transition` parameter set to `false`
# ...is called without being surrounded by:
# - `accept_input(NONE)` or `accept_input(SKIP), and,
# - `accept_input(ALL)
#
# (Note it is impossible to determine the value of arguments to the commands above if the arguments
# are anything other than a literal.)
func _allows_undesired_player_movement(event: ESCGrammarStmts.Event) -> bool:
	var block: ESCGrammarStmts.Block = event.get_body()

	if not _is_valid_block(block):
		return false

	if event.get_num_statements_in_block() < 2:
		return false

	var transition_line: int = 0
	var auto_change_scene_line: int = 0
	var accept_input_disable_line: int = 0
	var accept_input_enable_line: int = 0
	var statement_num: int = 1

	var allows_for_undesired_player_movement: bool = false

	for statement in block.get_statements():
		var command_expression: ESCGrammarExpr = statement.get_expression()

		match _get_command_name_from(command_expression):
			CHANGE_SCENE_COMMAND_NAME:
				if _get_command_nth_argument_from(command_expression, 2) == false:
					auto_change_scene_line = statement_num
			TRANSITION_COMMAND_NAME:
				transition_line = statement_num
			ACCEPT_INPUT_COMMAND_NAME:
				if _get_command_nth_argument_from(command_expression, 1) in ACCEPT_INPUT_DISABLE_ARGS:
					accept_input_disable_line = statement_num
				elif _get_command_nth_argument_from(command_expression, 1) == ACCEPT_INPUT_ENABLE_ARG:
					accept_input_enable_line = statement_num

		statement_num += 1

	return _lines_allow_for_undesired_player_movement(
		transition_line,
		auto_change_scene_line,
		accept_input_disable_line,
		accept_input_enable_line
	)


func _lines_allow_for_undesired_player_movement(
	transition_line: int,
	auto_change_scene_line: int,
	accept_input_disable_line: int,
	accept_input_enable_line: int
):

	if transition_line > 0 or auto_change_scene_line > 0:
		var transition_or_auto_change_scene_line: int = min(transition_line, auto_change_scene_line)

		if accept_input_disable_line == 0:
			return true

		if accept_input_disable_line > transition_or_auto_change_scene_line:
			return true

		if accept_input_enable_line == 0:
			return true

		if accept_input_enable_line < transition_or_auto_change_scene_line:
			return true

	return false


func _check_for_change_scene_command(event: ESCGrammarStmts.Event) -> bool:
	var block: ESCGrammarStmts.Block = event.get_body()

	if not _is_valid_block(block):
		return false

	for statement in block.get_statements():
		if not statement.has_method('get_expression'):
			continue

		if _get_command_name_from(statement.get_expression()) == CHANGE_SCENE_COMMAND_NAME:
			return true

	return false


func _is_valid_block(block: ESCGrammarStmts.Block) -> bool:
	if block == null:
		return false

	var statements: Array = block.get_statements()

	if statements == null or statements.size() == 0:
		return false

	return true


func _get_command_name_from(expression: ESCGrammarExpr) -> String:
	if expression == null \
		or expression.get_callee() == null \
		or expression.get_callee().get_name() == null \
		or expression.get_callee().get_name().get_lexeme() == null:
		return ""

	return expression.get_callee().get_name().get_lexeme().to_lower()


func _get_command_nth_argument_from(expression: ESCGrammarExpr, arg_num: int):
	var arg_pos: int = 1

	for arg in expression.get_arguments():
		if arg_pos == arg_num and arg.has_method('get_value'):
			if arg.get_value() is String:
				return arg.get_value().to_lower()
			else:
				return arg.get_value()

		arg_pos += 1

	return null
