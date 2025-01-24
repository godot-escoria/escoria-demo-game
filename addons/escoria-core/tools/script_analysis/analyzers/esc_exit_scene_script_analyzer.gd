extends ESCScriptAnalyzer
class_name ESCExitSceneScriptAnalyzer


const EXIT_SCENE_EVENT_NAME = "exit_scene"
const ACCEPT_INPUT_DISABLE_ARGS = ["none", "skip"]

const CHANGE_SCENE_MISSING_MESSAGE = "Event ':exit_scene' is missing 'change_scene' command. Scene might not change as expected."

const MISSING_ACCEPT_INPUT_MESSAGE = \
	"Event ':exit_scene' may allow for the player character to move while exiting and changing the scene." \
	+ " To prevent this, ensure a call to 'accept_input' with an argument evaluating to 'NONE' or 'SKIP' is" \
	+ " made before any calls to 'transition' and/or 'change_scene'."


# These are vars because they have to be, but should be treated as consts
var TRANSITION_COMMAND_NAME = TransitionCommand.new().get_command_name()
var CHANGE_SCENE_COMMAND_NAME = ChangeSceneCommand.new().get_command_name()
var ACCEPT_INPUT_COMMAND_NAME = AcceptInputCommand.new().get_command_name()

var _has_change_scene_command: bool = false

var _accept_input_disable_missing: bool = false

var _accept_input_disabled_token: ESCToken = null


func analyze(statements: Array) -> void:
	if not statements is Array:
		statements = [statements]

	for statement in statements:
		if statement.get_event_name().to_lower() == EXIT_SCENE_EVENT_NAME:
			_execute(statement)

			if not _has_change_scene_command:
				_rich_messages.append(ESCSafeLogging.log_warn.bind(self, CHANGE_SCENE_MISSING_MESSAGE))

			if _accept_input_disable_missing:
				_rich_messages.append(ESCSafeLogging.log_warn.bind(self, MISSING_ACCEPT_INPUT_MESSAGE))

			break


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

	if callee.get_command_name() == CHANGE_SCENE_COMMAND_NAME:
		_has_change_scene_command = true

		# First arg is always the path of the scene to transition to.
		# Second arg determines whether the transition is automatic, and defaults to true
		if args.size() > 1:
			var is_auto_transition = args[1] as bool

			if is_auto_transition != null and not is_auto_transition:
				_check_for_missing_accept_input_disable(_accept_input_disabled_token)
	elif callee.get_command_name() == TRANSITION_COMMAND_NAME:
		_check_for_missing_accept_input_disable(_accept_input_disabled_token)
	elif callee.get_command_name() == ACCEPT_INPUT_COMMAND_NAME:
		var first_arg = args[0] as String

		if first_arg != null and first_arg.to_lower() in ACCEPT_INPUT_DISABLE_ARGS:
			_accept_input_disabled_token = expr.get_paren_token()
			_environment.define(_accept_input_disabled_token.get_lexeme(), true)

	return ESCExecution.RC_OK


# Parameters:
# - accept_input_token: ESCToken containing info pertaining to command about to be called; also used
# as a key in the environment/scope to serve as a marker to check concerning whether `accept_input`
# has previously been called with the appropriate argument
func _check_for_missing_accept_input_disable(accept_input_token: ESCToken) -> void:
	if accept_input_token == null:
		_accept_input_disable_missing = true
		return

	if not _environment.is_valid_key(accept_input_token) or not _environment.get_value(accept_input_token):
		_accept_input_disable_missing = true
