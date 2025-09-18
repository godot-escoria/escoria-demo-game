## Factory class for producing an ASHES interpreter.
extends RefCounted
class_name ESCInterpreterFactory


static var _interpreter: ESCInterpreter = null


## Produces an interpreter as a singleton.
static func create_interpreter() -> ESCInterpreter:
	if not _interpreter:
		_interpreter = load("res://addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd").new(ESCCompiler.load_commands(), ESCCompiler.load_globals())
		return _interpreter

	_interpreter = load("res://addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd").new([], _interpreter.get_global_values())

	return _interpreter


static func reset_interpreter() -> void:
	if is_instance_valid(_interpreter):
		_interpreter.cleanup()
		_interpreter = null
