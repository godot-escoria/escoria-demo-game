extends Reference
class_name ESCInterpreter


var _globals: ESCEnvironment
var _environment: ESCEnvironment = _globals

var _locals: Dictionary = {}


func _init(callables: Array, globals: Dictionary):
	_globals = ESCEnvironment.new()

	for callable in callables:
		_globals.define(callable.get_command_name(), callable)

	for key in globals.keys():
		_globals.define(key, globals[key])


func interpret(statements: Array) -> void:
	for stmt in statements:
		var ret = _execute(stmt)

		if ret is ESCParseError:
			# TODO: runtime error handling
			pass



# Visitor implementations
func visitBlockStmt(stmt: ESCGrammarStmts.Block):
	var env: ESCEnvironment = ESCEnvironment.new()
	env.init(_environment)

	return _execute_block(stmt.get_statements(), env)


func visitEventStmt(stmt: ESCGrammarStmts.Event):
	var event: ESCEvent = ESCEvent.new("")
	event.init(stmt.get_name().get_lexeme(), stmt.get_flags())


func visitExpressionStmt(stmt: ESCGrammarStmts.ESCExpression):
	return _evaluate(stmt.get_expression())


func visitCallExpr(expr: ESCGrammarExprs.Call):
	var callee = _evaluate(expr.get_callee())

	var args: Array = []

	for arg in expr.get_arguments():
		args.append(_evaluate(arg))

	if not callee is ESCBaseCommand:
		escoria.logger.error(
			self,
			"Can only call valid commands."
		)

	var argument_descriptor = callee.configure()
	var prepared_arguments = argument_descriptor.prepare_arguments(
		args
	)

	if callee.validate(prepared_arguments):
		escoria.logger.debug(
			self,
			"Running command %s with parameters %s."
					% [callee.name, prepared_arguments]
		)
		var rc = callee.run(prepared_arguments)

		return rc

	return null


func visitVariableExpr(expr: ESCGrammarExprs.Variable):
	return _lookUpVariable(expr.get_name(), expr)


func visitLiteralExpr(expr: ESCGrammarExprs.Literal):
	return expr.get_value()


func resolve(expr: ESCGrammarExpr, depth: int):
	_locals[expr] = depth


# Private methods
func _lookUpVariable(name: ESCToken, expr: ESCGrammarExpr):
	var distance: int = _locals[expr] if _locals.has(expr) else -1

	if distance == -1:
		return _globals.get_value(name)
	else:
		return _environment.get_at(distance, name.get_lexeme())


func _evaluate(expr: ESCGrammarExpr):
	var ret = expr.accept(self)

	# TODO: Error handling
	return ret


func _execute(stmt: ESCGrammarStmt):
	var ret = stmt.accept(self)

	# TODO: Error handling
	return ret


func _execute_block(statements: Array, env: ESCEnvironment):
	var previous_env = _environment
	var ret = null

	_environment = env

	for stmt in statements:
		ret = _execute(stmt)

		if ret:
			break

	_environment = previous_env

	return ret
