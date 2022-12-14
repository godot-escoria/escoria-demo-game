extends Reference
class_name ESCParser


var _tokens: Array
var _current: int = 0

var _compiler


func init(compiler, tokens: Array) -> void:
	_compiler = compiler
	_tokens = tokens


func parse() -> Array:
	var statements: Array = []

	while not _at_end():
		statements.append(_declaration())

	return statements


func _declaration() -> ESCGrammarStmt:
	var retStmt

	if _match(ESCTokenType.TokenType.COLON):
		retStmt = _event_declaration()

		if retStmt is ESCParseError:
			_synchronize()
			return null
		else:
			return retStmt

	if _match(ESCTokenType.TokenType.VAR):
		retStmt = _var_declaration()

		if retStmt is ESCParseError:
			_synchronize()
			return null
		else:
			return retStmt

	retStmt = _statement()

	if retStmt is ESCParseError:
		_synchronize()
		return null

	return retStmt


func _event_declaration():
	var name = _consume(ESCTokenType.TokenType.IDENTIFIER, "Expect event name.")

	if name is ESCParseError:
		return name

	var flags: Array = []

	var has_flags: bool = _match(ESCTokenType.TokenType.PIPE)

	while has_flags:
		var flag = _consume(ESCTokenType.TokenType.IDENTIFIER, "Expect flag name.")

		if flag is ESCParseError:
			return flag

		flags.append(flag)

		has_flags = _match(ESCTokenType.TokenType.PIPE)

	var ret = ESCGrammarStmts.Event.new()
	ret.init(name, flags)
	
	return ret


func _expression():
	var expr = _assignment()

	return expr


func _statement():
	if _match(ESCTokenType.TokenType.IF):
		var stmt = _if_statement()

		if stmt is ESCParseError:
			return stmt

	if _matchInOrder([ESCTokenType.TokenType.NEWLINE, ESCTokenType.TokenType.INDENT]):
		var block = _block()

		if block is ESCParseError:
			return block

		var ret = ESCGrammarStmts.Block.new()
		ret.init(block)
		return ret

	return _expressionStatement()


func _if_statement():
	var condition = _expression()

	if condition is ESCParseError:
		return condition

	var colon_token = _consume(ESCTokenType.TokenType.COLON, "Expect ':' after if condition.")

	if colon_token is ESCParseError:
		return colon_token

	var then_branch = _statement()

	if then_branch is ESCParseError:
		return then_branch

	var elif_branches = []

	while _match(ESCTokenType.TokenType.ELIF):
		var elif_branch = _elif_statement()

		if elif_branch is ESCParseError:
			return elif_branch

		elif_branches.append(elif_branch)

	var else_branch = null

	if _match(ESCTokenType.TokenType.ELSE):
		else_branch = _statement()

		if else_branch is ESCParseError:
			return else_branch

	var toRet = ESCGrammarStmts.If.new()
	toRet.init(condition, then_branch, elif_branches, else_branch)
	return toRet


func _elif_statement():
	var condition = _expression()

	if condition is ESCParseError:
		return condition

	var colon_token = _consume(ESCTokenType.TokenType.COLON, "Expect ':' after elif condition.")

	var then_branch = _statement()

	if then_branch is ESCParseError:
		return then_branch

	var toRet = ESCGrammarStmts.If.new()
	toRet.init(condition, then_branch, null)
	return toRet


func _expressionStatement():
	var expr = _expression()

	if expr is ESCParseError:
		return expr

	var consume = _consume(ESCTokenType.TokenType.NEWLINE, "Expect NEWLINE after expression statement.")

	if consume is ESCParseError:
		return consume

	var ret = ESCGrammarStmts.ESCExpression.new()
	ret.init(expr)
	return ret


func _block():
	var statements: Array = []

	while not _check(ESCTokenType.TokenType.DEDENT) and not _at_end():
		var decl = _declaration()

		if decl is ESCParseError:
			return decl

		statements.append(decl)

	_consume(ESCTokenType.TokenType.DEDENT, "Expected DEDENT after block.")
	return statements


func _assignment():
	var expr = _or()

	if expr is ESCParseError:
		return expr

	if _match(ESCTokenType.TokenType.EQUAL):
		var equals: ESCToken = _previous()
		var value = _assignment()

		if value is ESCParseError:
			return value

		if expr is ESCGrammarExprs.Variable:
			var name = expr.get_name()
			var ret = ESCGrammarExprs.Assign.new()
			ret.init(name, value)
			return ret
		elif expr is ESCGrammarExpr.Get:
			var ret = ESCGrammarExprs.Set.new()
			ret.init(expr.get_object(), expr.get_name(), value)
			return ret

		return _error(equals, "Invalid assignment type.")

	return expr


func _or():
	var expr = _and()

	if expr is ESCParseError:
		return expr

	while _match(ESCTokenType.TokenType.OR):
		var operator: ESCToken = _previous()
		var right = _and()

		if right is ESCParseError:
			return right

		expr = ESCGrammarExprs.Logical.new()
		expr.init(expr, operator, right)

	return expr


func _and():
	var expr = _equality()

	if expr is ESCParseError:
		return expr

	while _match(ESCTokenType.TokenType.AND):
		var operator: ESCToken = _previous()
		var right = _equality()

		if right is ESCParseError:
			return right

		expr = ESCGrammarExprs.Logical.new()
		expr.init(expr, operator, right)

	return expr


func _equality():
	var expr = _comparison()

	if expr is ESCParseError:
		return expr

	while _match([ESCTokenType.TokenType.BANG_EQUAL, ESCTokenType.TokenType.EQUAL_EQUAL]):
		var operator: ESCToken = _previous()
		var right = _comparison()

		if right is ESCParseError:
			return right

		expr = ESCGrammarExprs.Binary.new()
		expr.init(expr, operator, right)

	return expr


func _comparison():
	var expr = _term()

	if expr is ESCParseError:
		return expr

	while _match([
		ESCTokenType.TokenType.GREATER,
		ESCTokenType.TokenType.GREATER_EQUAL,
		ESCTokenType.TokenType.LESS,
		ESCTokenType.TokenType.LESS_EQUAL]):

		var operator: ESCToken = _previous()
		var right = _term()

		if right is ESCParseError:
			return right

		expr = ESCGrammarExprs.Binary.new()
		expr.init(expr, operator, right)

	return expr


func _term():
	var expr = _factor()

	if expr is ESCParseError:
		return expr

	while _match([ESCTokenType.TokenType.MINUS, ESCTokenType.TokenType.PLUS]):
		var operator: ESCToken = _previous()
		var right = _factor()

		if right is ESCParseError:
			return right

		expr = ESCGrammarExprs.Binary.new()
		expr.init(expr, operator, right)

	return expr


func _factor():
	var expr = _unary()

	if expr is ESCParseError:
		return expr

	while _match([ESCTokenType.TokenType.SLASH, ESCTokenType.TokenType.STAR]):
		var operator: ESCToken = _previous()
		var right = _unary()

		if right is ESCParseError:
			return right

		expr = ESCGrammarExprs.Binary.new()
		expr.init(expr, operator, right)

	return expr


func _unary():
	if _match([ESCTokenType.TokenType.BANG, ESCTokenType.TokenType.MINUS]):
		var operator: ESCToken = _previous()
		var right: ESCGrammarExpr = _unary()

		var ret = ESCGrammarExprs.Unary.new()
		ret.init(operator, right)
		return ret

	return _call()


func _call():
	var expr = _primary()

	if expr is ESCParseError:
		return expr

	if expr is ESCGrammarExprs.Variable:
		expr = _finishCall(expr)

		if expr is ESCParseError:
			return expr

	return expr


func _finishCall(callee: ESCGrammarExpr):
	var args: Array = []
	var toReturn = null

	if not _check(ESCTokenType.TokenType.NEWLINE):
		var done: bool = false

		while not done:
			if args.size() >= 255:
				return _error(_peek(), "Can't have more than 255 arguments.")

			var expr = _expression()

			if expr is ESCParseError:
				return expr

			args.append(expr)

			#done = _match(ESCTokenType.TokenType.COMMA)
			done = _peek().get_type() == ESCTokenType.TokenType.NEWLINE

	var paren = _peek()

	if paren.get_type() != ESCTokenType.TokenType.NEWLINE:
		return _error(ESCTokenType.TokenType.NEWLINE, "Expect NEWLINE after arguments.")

	var ret = ESCGrammarExprs.Call.new()
	ret.init(callee, paren, args)
	return ret


func _primary():
	if _match(ESCTokenType.TokenType.FALSE):
		var ret = ESCGrammarExprs.Literal.new()
		ret.init(false)
		return ret

	if _match(ESCTokenType.TokenType.TRUE):
		var ret = ESCGrammarExprs.Literal.new()
		ret.init(true)
		return ret

	if _match(ESCTokenType.TokenType.NIL):
		var ret = ESCGrammarExprs.Literal.new()
		ret.init(null)
		return ret

	if _match([ESCTokenType.TokenType.NUMBER, ESCTokenType.TokenType.STRING]):
		var ret = ESCGrammarExprs.Literal.new()
		ret.init(_previous().get_literal())
		return ret

	if _match(ESCTokenType.TokenType.IDENTIFIER):
		var ret = ESCGrammarExprs.Variable.new()
		ret.init(_previous())
		return ret

	if _match(ESCTokenType.TokenType.LEFT_PAREN):
		var expr = _expression()

		if expr is ESCParseError:
			return expr

		_consume(ESCTokenType.TokenType.RIGHT_PAREN, "Expect ')' after expression.")

		var ret = ESCGrammarExprs.Grouping.new()
		ret.init(expr)
		return ret

	return _error(_peek(), "Expect expression.")


func _var_declaration() -> ESCGrammarStmt:
	var name = _consume(ESCTokenType.TokenType.IDENTIFIER, "Expect variable name.")

	var initializer: ESCGrammarExpr = null

	if _match(ESCTokenType.TokenType.EQUAL):
		initializer = _expression()

	_consume(ESCTokenType.TokenType.NEWLINE, "Expect newline after variable declaration.")

	var ret = ESCGrammarStmts.Var.new()
	ret.init(name, initializer)
	return ret


func _at_end() -> bool:
	return _peek().get_type() == ESCTokenType.TokenType.EOF


func _peek() -> ESCToken:
	return _tokens[_current]


func _match(tokenTypes) -> bool:
	if not tokenTypes is Array:
		tokenTypes = [tokenTypes]

	for type in tokenTypes:
		if _check(type):
			_advance()
			return true

	return false


func _matchInOrder(tokenTypes) -> bool:
	if not tokenTypes is Array:
		tokenTypes = [tokenTypes]

	for type in tokenTypes:
		if not _check(type):
			return false

		_advance()

	return true


func _consume(tokenType, message: String):
	if _check(tokenType):
		return _advance()

	return _error(_peek(), message)


func _check(tokenType) -> bool:
	if _at_end():
		return false

	return _peek().get_type() == tokenType


func _previous() -> ESCToken:
	return _tokens[_current - 1]


func _advance() -> ESCToken:
	if not _at_end():
		_current += 1

	return _previous()


func _error(token: ESCToken, message: String) -> ESCParseError:
	_compiler.had_error = true
	escoria.logger.warn(
		self,
		message
	)

	return ESCParseError.new()


func _synchronize() -> void:
	_advance()

	while not _at_end():
		if _previous().get_type() == ESCTokenType.TokenType.NEWLINE:
			return

		match _peek().get_type():
			ESCTokenType.TokenType.VAR,\
			ESCTokenType.TokenType.IF,\
			ESCTokenType.TokenType.WHILE,\
			ESCTokenType.TokenType.PRINT,\
			ESCTokenType.TokenType.RETURN:
				return

	_advance()
