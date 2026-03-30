## Factory class for producing an ASHES interpreter.
class_name ESCInterpreterFactory
extends RefCounted

const ESC_INTERPRETER_SCRIPT := preload(
	"res://addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd"
)


static var _interpreter: ESCInterpreter = null


## Produces an interpreter as a singleton.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `ESCInterpreter` value. (`ESCInterpreter`)
static func create_interpreter(channel_name: String = "") -> ESCInterpreter:
	return create_utility_interpreter(channel_name)


## Produces an interpreter for non-runtime utility work such as resolving or
## evaluating statements outside the event manager.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |channel_name|`String`|Optional channel name to assign to the created interpreter.|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a cached-or-reseeded `ESCInterpreter` instance for utility usage. (`ESCInterpreter`)
static func create_utility_interpreter(channel_name: String = "") -> ESCInterpreter:
	if not _interpreter:
		_interpreter = ESC_INTERPRETER_SCRIPT.new(
			ESCCompiler.load_commands(),
			ESCCompiler.load_globals(),
			channel_name
		)
	else:
		_interpreter = ESC_INTERPRETER_SCRIPT.new(
			[],
			_interpreter.get_global_values(),
			channel_name
		)

	return _interpreter


## Produces a fresh interpreter intended for event-manager runtime execution.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |channel_name|`String`|Optional channel name to assign to the created interpreter.|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a newly-created `ESCInterpreter` instance for runtime usage. (`ESCInterpreter`)
static func create_runtime_interpreter(channel_name: String = "") -> ESCInterpreter:
	var interpreter := ESC_INTERPRETER_SCRIPT.new(
		ESCCompiler.load_commands(),
		ESCCompiler.load_globals(),
		channel_name
	)
	return interpreter


static func reset_interpreter() -> void:
	if is_instance_valid(_interpreter):
		_interpreter.cleanup()
		_interpreter = null
