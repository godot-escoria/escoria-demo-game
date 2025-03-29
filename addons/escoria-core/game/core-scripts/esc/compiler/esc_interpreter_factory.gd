extends RefCounted
class_name ESCInterpreterFactory


static var _interpreter: ESCInterpreter = null


static func create_interpreter() -> ESCInterpreter:
	if not _interpreter:
		_interpreter = load("res://addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd").new(ESCCompiler.load_commands(), ESCCompiler.load_globals())
		return _interpreter

	_interpreter = load("res://addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd").new([], _interpreter.get_global_values())

	return _interpreter
