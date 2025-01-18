extends ESCScriptAnalyzer
class_name ESCExitSceneScriptAnalyzer


const EXIT_SCENE_EVENT_NAME = "exit_scene"
const TRANSITION_COMMAND_NAME = "transition"
const CHANGE_SCENE_COMMAND_NAME = "change_scene"


# Returns: Array of strings for any issues detected.
func analyze(statements: Array) -> Array[String]:
	var issue_messages: Array[String] = []

	for statement in statements:
		if statement.get_event_name().to_lower() == EXIT_SCENE_EVENT_NAME:
			issue_messages = _analyze_exit_scene_event(statement)
			break

	issue_messages.all(print)
	return issue_messages


func _analyze_exit_scene_event(event) -> Array[String]:
	var issue_messages: Array[String] = []

	if not _check_for_change_scene_command(event):
		issue_messages.push_back("Event ':exit_scene' is missing 'change_scene' command. Scene might not change as expected.")

	return issue_messages


# Check to see if the player is still able to move in the case where either:
# - `transition()`, or,
# - `change_scene()` with the `enable_automatic_transition` parameter set to `false`
# ...is called without being surrounded by:
# - `accept_input(NONE)` or `accept_input(SKIP), and,
# - `accept_input(ALL)
func _check_for_undesired_player_movement(event: ESCGrammarStmts.Event):
	if event.get_num_statements_in_block() < 2:
		return

	pass


func _check_for_change_scene_command(event: ESCGrammarStmts.Event) -> bool:
	var block: ESCGrammarStmts.Block = event.get_body()

	if block == null:
		return false

	var statements: Array = block.get_statements()

	if statements == null or statements.size() == 0:
		return false

	for statement in statements:
		if _get_command_name_from(statement.get_expression()) == CHANGE_SCENE_COMMAND_NAME:
			return true

	return false


func _get_command_name_from(expression: ESCGrammarExpr) -> String:
	if expression == null \
		or expression.get_callee() == null \
		or expression.get_callee().get_name() == null \
		or expression.get_callee().get_name().get_lexeme() == null:
		return ""

	return expression.get_callee().get_name().get_lexeme().to_lower()
