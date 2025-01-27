extends ESCScriptAnalyzer
class_name ESCExitSceneScriptAnalyzer


const EXIT_SCENE_EVENT_NAME = "exit_scene"
const ACCEPT_INPUT_DISABLE_ARGS = ["none", "skip"]

const CHANGE_SCENE_MISSING_MESSAGE = "Event ':exit_scene' is missing 'change_scene' command. Scene might not change as expected. Ignore this warning if the command was omitted on purpose."

const COMMANDS_AFTER_CHANGE_SCENE_MESSAGE = "Event ':exit_scene' may have commands that are expected to be run after a call to 'change_scene'. Such commands will not be executed."

const MISSING_ACCEPT_INPUT_MESSAGE = \
	"Event ':exit_scene' may allow for the player character to move while exiting and changing the scene." \
	+ " To prevent this, ensure a call to 'accept_input' with an argument evaluating to 'NONE' or 'SKIP' is" \
	+ " made before any calls to 'transition' and/or 'change_scene'."

const BULLET_CHARACTER = "- "


# These are vars because they have to be, but should be treated as consts
var TRANSITION_COMMAND_NAME = TransitionCommand.new().get_command_name()
var CHANGE_SCENE_COMMAND_NAME = ChangeSceneCommand.new().get_command_name()
var ACCEPT_INPUT_COMMAND_NAME = AcceptInputCommand.new().get_command_name()

var _has_change_scene_command: bool = false

var _has_commands_after_change_scene_command: bool = false

var _change_scene_token: ESCToken = null

var _accept_input_disable_missing: bool = false

var _accept_input_token: ESCToken = null


func analyze(statements: Array) -> void:
	if not statements is Array:
		statements = [statements]

	for statement in statements:
		if statement.get_event_name().to_lower() == EXIT_SCENE_EVENT_NAME:
			_execute(statement)

			_add_warning_messages()

			break


func _add_warning_messages() -> void:
	var messages: Array[String] = []

	if not _has_change_scene_command:
		messages.append(BULLET_CHARACTER + CHANGE_SCENE_MISSING_MESSAGE)

	if _accept_input_disable_missing:
		messages.append(BULLET_CHARACTER + MISSING_ACCEPT_INPUT_MESSAGE)

	if _has_commands_after_change_scene_command:
		messages.append(BULLET_CHARACTER + COMMANDS_AFTER_CHANGE_SCENE_MESSAGE)

	if not messages.is_empty():
		_rich_messages.append(ESCSafeLogging.log_warn.bind(self, "\n".join(messages)))


func _execute_block(statements: Array, env: ESCEnvironment):
	var previous_env = _environment
	var ret = null

	_environment = env

	for stmt in statements:
		ret = _execute(stmt)

	_environment = previous_env

	return ret


# Visitor overriding
func visit_call_expr(expr: ESCGrammarExprs.Call):
	var callee = _evaluate(expr.get_callee())

	var args: Array = []

	for arg in expr.get_arguments():
		arg = _evaluate(arg)

		# "Adapter" for current ESC commands since they don't currently take
		# ESCObject's (or ESCRoom's) as arguments.
		if arg is ESCObject or arg is ESCRoom:
			arg = arg.global_id

		args.append(arg)

	var command_name: String = _get_command_name(callee)

	_has_commands_after_change_scene_command = _has_change_scene_command_in_scope()

	if command_name == CHANGE_SCENE_COMMAND_NAME:
		_has_change_scene_command = true

		_change_scene_token = expr.get_paren_token()
		_environment.define(_change_scene_token.get_lexeme(), true)

		# First arg is always the path of the scene to transition to.
		# Second arg determines whether the transition is automatic, and defaults to true
		if args.size() > 1:
			var is_auto_transition = args[1] as bool

			if is_auto_transition != null and not is_auto_transition:
				_check_for_missing_accept_input_disable()
	elif command_name == TRANSITION_COMMAND_NAME:
		_check_for_missing_accept_input_disable()
	elif command_name == ACCEPT_INPUT_COMMAND_NAME:
		var first_arg = args[0] as String

		if first_arg != null and first_arg.to_lower() in ACCEPT_INPUT_DISABLE_ARGS:
			_accept_input_token = expr.get_paren_token()
			_environment.define(_accept_input_token.get_lexeme(), true)

	return ESCExecution.RC_OK


# as a key in the environment/scope to serve as a marker to check concerning whether `accept_input`
# has previously been called with the appropriate argument
func _check_for_missing_accept_input_disable() -> void:
	if _accept_input_token == null:
		_accept_input_disable_missing = true
		return

	_accept_input_disable_missing = \
		not _environment.is_valid_key(_accept_input_token) \
		or not _environment.get_value(_accept_input_token)


func _has_change_scene_command_in_scope() -> bool:
	if _change_scene_token == null:
		return false

	return \
		_environment.is_valid_key(_change_scene_token) \
		and _environment.get_value(_change_scene_token)


func _get_command_name(callee) -> String:
	# if we don't have a command to run, check against any built-in functions and,
	# if one is found and is executed, we're done
	if callee is ESCBaseCommand:
		return callee.get_command_name()

	return callee
