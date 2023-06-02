extends Reference
class_name ESCInterpreterFactory


var _interpreter: ESCInterpreter = null


func create_interpreter() -> ESCInterpreter:
	if not _interpreter:
		_interpreter = load("res://addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd").new(ESCCompiler.load_commands(), ESCCompiler.load_globals())
		return _interpreter

	_interpreter = load("res://addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd").new([], _interpreter.get_global_values())

	return _interpreter
