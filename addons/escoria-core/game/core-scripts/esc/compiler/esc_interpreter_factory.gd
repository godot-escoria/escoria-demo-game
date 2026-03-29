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
	if not _interpreter:
		_interpreter = ESC_INTERPRETER_SCRIPT.new(
			ESCCompiler.load_commands(),
			ESCCompiler.load_globals()
		)
	else:
		_interpreter = ESC_INTERPRETER_SCRIPT.new(
			[],
			_interpreter.get_global_values()
		)

	_interpreter.set_channel_name(channel_name)
	return _interpreter


static func reset_interpreter() -> void:
	if is_instance_valid(_interpreter):
		_interpreter.cleanup()
		_interpreter = null
