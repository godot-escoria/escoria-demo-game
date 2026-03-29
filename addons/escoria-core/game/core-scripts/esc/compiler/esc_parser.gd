## Class that handles parsing of scanned tokens in order to generate a list of
## statements for the interpreter to execute.
##
## Note that the vast majority of this class consists of (effectively) private methods
## in order to facilitate encapsulation, but if you're interested in how the parser
## is implemented, [check out the class in GitHub](https://github.com/godot-escoria/escoria-demo-game/blob/main/addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd)
class_name ESCParser
extends RefCounted


var _tokens: Array
var _current: int = 0
var _associated_object_global_id = ""

var _loop_level: int = 0
var _dialog_level: int = 0

var _compiler


## Initialization method. Must be called after instantiation.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |compiler|`Variant`|a reference to the ASHES compiler; used primarily for error tracking|yes|[br]
## |tokens|`Array`|an array of tokens produced by the ASHES scanner|yes|[br]
## |associated_object_global_id|`String`|string containing the global ID of the associated object/room to be passed on to events|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func init(compiler, tokens: Array, associated_object_global_id: String) -> void:
	_compiler = compiler
	_tokens = tokens
	_associated_object_global_id = associated_object_global_id


## Entry point for the parser. Begins parsing the tokens passed in to the `init` method.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns an array of statements for the interpreter to execute. (`Array`)
func parse() -> Array:
	_loop_level = 0
	_dialog_level = 0
	var statements: Array = []

	while not _at_end():
		var declaration = _declaration()
		if declaration != null:
			statements.append(declaration)

	return statements


func _declaration() -> ESCGrammarStmt:
	while _match(ESCTokenType.TokenType.NEWLINE) or _match(ESCTokenType.TokenType.DEDENT):
		pass

	if _at_end():
		return null

	var ret_stmt

	if _match(ESCTokenType.TokenType.COLON):
		ret_stmt = _event_declaration()

		if ret_stmt is ESCParseError:
			_synchronize()
			return null

		return ret_stmt

	if _match(ESCTokenType.TokenType.VAR):
		ret_stmt = _var_declaration()

		if ret_stmt is ESCParseError:
			_synchronize()
			return null

		return ret_stmt

	if _match(ESCTokenType.TokenType.GLOBAL):
		ret_stmt = _global_declaration()

		if ret_stmt is ESCParseError:
			_synchronize()
			return null

		return ret_stmt

	ret_stmt = _statement()

	if ret_stmt is ESCParseError:
		_synchronize()
		return null

	return ret_stmt


func _event_declaration():
	var name = _consume(ESCTokenType.TokenType.IDENTIFIER, "Expect event name. Got '%s' instead." % _peek().get_lexeme())

	if name is ESCParseError:
		return name

	var target = null

	if _check(ESCTokenType.TokenType.STRING) or _check(ESCTokenType.TokenType.IDENTIFIER):
		var expr = _primary()

		if expr is ESCParseError:
			return expr

		if expr is ESCGrammarExprs.Variable:
			target = _literal_from_identifier(expr)
		else:
			target = expr

	var flags: Dictionary = {}

	var has_flags: bool = _match(ESCTokenType.TokenType.PIPE)

	while has_flags:
		var flag = _consume(
			ESCTokenType.TokenType.IDENTIFIER,
			"Event '%s': Expect valid flag name. Got '%s' instead." % [name.get_lexeme(), _peek().get_lexeme()])

		if flag is ESCParseError:
			return flag

		var flag_condition = null

		if _match(ESCTokenType.TokenType.LESS):
			if not _check(ESCTokenType.TokenType.IDENTIFIER):
				return _error(_peek(), "Condition for flag '%s' must be a global variable." % flag.get_lexeme())

			flag_condition = _primary()

			if flag_condition is ESCParseError:
				return flag_condition

			var close_predicate_token = _consume(
				ESCTokenType.TokenType.GREATER,
				"For flag '%s', only one (global) variable may be used and must be enclosed between '<' and '>'." % flag.get_lexeme())

			if close_predicate_token is ESCParseError:
				return close_predicate_token

		flags[flag.get_lexeme()] = flag_condition

		has_flags = _match(ESCTokenType.TokenType.PIPE)

	if _match_in_order([ESCTokenType.TokenType.NEWLINE, ESCTokenType.TokenType.INDENT]):
		var body = ESCGrammarStmts.Block.new()
		body.init(_block())

		var ret = ESCGrammarStmts.Event.new()
		ret.init(name, target, flags, body, _associated_object_global_id)

		return ret

	return _error(_peek(), "Expected block after event declaration for '%s'. Code blocks require tab(s) at the start of a line." % name.get_lexeme())


func _literal_from_identifier(expr: ESCGrammarExprs.Variable) -> ESCGrammarExprs.Literal:
	var lexeme = expr.get_name().get_lexeme()

	if lexeme.begins_with(ESCScanner.GLOBAL_ID_PREFIX):
		lexeme = lexeme.substr(1)

	var literal = ESCGrammarExprs.Literal.new()
	literal.init(lexeme)

	return literal


func _expression():
	var expr = _assignment()

	return expr


func _statement():
	if _match(ESCTokenType.TokenType.IF):
		var stmt = _if_statement()
		return stmt
	if _match(ESCTokenType.TokenType.WHILE):
		var stmt = _while_statement()
		return stmt
	if _match(ESCTokenType.TokenType.PASS):
		var stmt = _pass_statement()
		return stmt
	if _match(ESCTokenType.TokenType.STOP):
		var stmt = _stop_statement()
		return stmt
	if _match(ESCTokenType.TokenType.QUESTION_BANG):
		var stmt = _dialog_statement()
		return stmt
	#if _match_in_order([ESCTokenType.TokenType.BREAK, ESCTokenType.TokenType.NEWLINE]):
	if _match(ESCTokenType.TokenType.BREAK):
		if _loop_level == 0 and _dialog_level == 0:
			return _error(_second_previous(), "'break' only allowed inside loops and dialogs")

		var stmt = _break_statement()
		return stmt
	if _match_in_order([ESCTokenType.TokenType.DONE, ESCTokenType.TokenType.NEWLINE]):
		if _dialog_level == 0:
			return _error(_second_previous(), "'done' only allowed inside dialogs")

		var stmt = _done_statement()
		return stmt
	if _match_in_order([ESCTokenType.TokenType.NEWLINE, ESCTokenType.TokenType.INDENT]) \
		or (_previous().get_type() == ESCTokenType.TokenType.NEWLINE and _match(ESCTokenType.TokenType.INDENT)):
		var block = _block()

		if block is ESCParseError:
			return block

		var ret = ESCGrammarStmts.Block.new()
		ret.init(block)
		return ret

	return _expression_statement()


func _if_statement():
	var condition = _expression()

	if condition is ESCParseError:
		return condition

	var colon_token = _consume(ESCTokenType.TokenType.COLON, "Expect ':' after if condition.")

	if colon_token is ESCParseError:
		return colon_token

	var consume = _consume_new_block_start("start of if statement")

	if consume:
		return consume

	var then_branch_block = _block()

	if then_branch_block is ESCParseError:
		return then_branch_block

	var then_branch = ESCGrammarStmts.Block.new()
	then_branch.init(then_branch_block)

	var elif_branches = []

	while _match(ESCTokenType.TokenType.ELIF):
		var elif_branch = _elif_statement()

		if elif_branch is ESCParseError:
			return elif_branch

		elif_branches.append(elif_branch)

	var else_branch = null

	if _match(ESCTokenType.TokenType.ELSE):
		colon_token = _consume(ESCTokenType.TokenType.COLON, "Expect ':' after 'else'.")

		if colon_token is ESCParseError:
			return colon_token

		consume = _consume_new_block_start("start of else statement")

		if consume:
			return consume

		var else_branch_block = _block()

		else_branch = ESCGrammarStmts.Block.new()
		else_branch.init(else_branch_block)

		if else_branch is ESCParseError:
			return else_branch

	var to_ret = ESCGrammarStmts.If.new()
	to_ret.init(condition, then_branch, elif_branches, else_branch)
	return to_ret


func _elif_statement():
	var condition = _expression()

	if condition is ESCParseError:
		return condition

	var colon_token = _consume(ESCTokenType.TokenType.COLON, "Expect ':' after elif condition.")

	var consume = _consume_new_block_start("start of elif statement")

	if consume:
		return consume

	var then_branch_block = _block()

	if then_branch_block is ESCParseError:
		return then_branch_block

	var then_branch = ESCGrammarStmts.Block.new()
	then_branch.init(then_branch_block)

	var to_ret = ESCGrammarStmts.If.new()
	to_ret.init(condition, then_branch, [], null)
	return to_ret


func _while_statement():
	_loop_level += 1

	var condition = _expression()

	if condition is ESCParseError:
		_loop_level -= 1
		return condition

	var colon_token = _consume(ESCTokenType.TokenType.COLON, "Expect ':' after condition.")

	if colon_token is ESCParseError:
		_loop_level -= 1
		return colon_token

	var consume = _consume_new_block_start("start of while loop")

	if consume:
		_loop_level -= 1
		return consume

	var block = _block()

	if block is ESCParseError:
		_loop_level -= 1
		return block

	var body = ESCGrammarStmts.Block.new()
	body.init(block)

	var to_ret = ESCGrammarStmts.While.new()
	to_ret.init(condition, body)

	_loop_level -= 1

	return to_ret


func _pass_statement():
	var consume = _consume(ESCTokenType.TokenType.NEWLINE, "Expected NEWLINE after pass statement.")

	if consume is ESCParseError:
		return consume

	var to_ret = ESCGrammarStmts.Pass.new()
	return to_ret


func _stop_statement():
	var consume = _consume(ESCTokenType.TokenType.NEWLINE, "Expected NEWLINE after stop statement.")

	if consume is ESCParseError:
		return consume

	var to_ret = ESCGrammarStmts.Stop.new()
	return to_ret


func _dialog_statement():
	_dialog_level += 1

	var args: Array = []

	if _match(ESCTokenType.TokenType.LEFT_PAREN):
		while true:
			var arg = _expression()

			if arg is ESCParseError:
				_dialog_level -= 1
				return arg

			args.append(arg)

			if not _match(ESCTokenType.TokenType.COMMA):
				break

		var consume = _consume(ESCTokenType.TokenType.RIGHT_PAREN, "Expect ')' after start dialog arguments.")

		if consume is ESCParseError:
			_dialog_level -= 1
			return consume

	if args.size() > 3:
		_dialog_level -= 1
		return _error(_peek(), "Start dialog cannot have more than 3 arguments.")

	var consume = _consume_new_block_start("dialog start")

	if consume is ESCParseError:
		_dialog_level -= 1
		return consume

	var options: Array = []

	while true:
		var dialog_option = _dialog_option_statement()

		if dialog_option is ESCParseError:
			_dialog_level -= 1
			return dialog_option

		options.append(dialog_option)

		if _match(ESCTokenType.TokenType.DEDENT):
			break

	var dialog: ESCGrammarStmts.Dialog = ESCGrammarStmts.Dialog.new()
	dialog.init(args, options)

	_dialog_level -= 1

	return dialog


func _consume_new_block_start(line_type: String):
	var consume = _consume(ESCTokenType.TokenType.NEWLINE, "Expect NEWLINE after %s." % line_type)

	if consume is ESCParseError:
		return consume

	consume = _consume(ESCTokenType.TokenType.INDENT, "Expect INDENT after %s." % line_type)

	if consume is ESCParseError:
		return consume

	return null


func _dialog_option_statement():
	var consume = _consume(ESCTokenType.TokenType.MINUS, "Expect '-' before dialog option")

	if consume is ESCParseError:
		return consume

	var expr = _expression()

	if expr is ESCParseError:
		return expr

	var condition = null

	if _match(ESCTokenType.TokenType.LEFT_SQUARE):
		condition = _expression()

		if condition is ESCParseError:
			return condition

		consume = _consume(ESCTokenType.TokenType.RIGHT_SQUARE, "Expect ']' after dialog option condition")

		if consume is ESCParseError:
			return consume

	consume = _consume_new_block_start("dialog option")

	var block_stmts = _block()

	if block_stmts is ESCParseError:
		return block_stmts

	var block = ESCGrammarStmts.Block.new()
	block.init(block_stmts)

	var option: ESCGrammarStmts.DialogOption = ESCGrammarStmts.DialogOption.new()
	option.init(expr, condition, block)
	return option


func _break_statement():
	var levels = null

	if _check([ESCTokenType.TokenType.IDENTIFIER, ESCTokenType.TokenType.NUMBER]):
		levels = _expression()

		if levels is ESCParseError:
			return levels

	var consume = _consume(ESCTokenType.TokenType.NEWLINE, "Expected either expression and NEWLINE, or just NEWLINE, after break statement")

	if consume is ESCParseError:
		return consume

	var ret = ESCGrammarStmts.Break.new()
	ret.init(levels)
	return ret


func _done_statement():
	var ret = ESCGrammarStmts.Done.new()
	return ret


func _expression_statement():
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

		if decl != null:
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

		if expr is ESCGrammarExprs.Get:
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

		var left_expr = expr
		expr = ESCGrammarExprs.Logical.new()
		expr.init(left_expr, operator, right)

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

		var left_expr = expr
		expr = ESCGrammarExprs.Logical.new()
		expr.init(left_expr, operator, right)

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

		var left_expr = expr
		expr = ESCGrammarExprs.Binary.new()
		expr.init(left_expr, operator, right)

	return expr


func _comparison():
	var expr = _term()

	if expr is ESCParseError:
		return expr

	# Flag predicates (e.g. TK<predicate>) should not be treated as comparisons.
	if _check(ESCTokenType.TokenType.GREATER) \
		and _check_next([ESCTokenType.TokenType.NEWLINE, ESCTokenType.TokenType.PIPE]):

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

		var left_expr = expr
		expr = ESCGrammarExprs.Binary.new()
		expr.init(left_expr, operator, right)

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

		var left_expr = expr
		expr = ESCGrammarExprs.Binary.new()
		expr.init(left_expr, operator, right)

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

		var left_expr = expr
		expr = ESCGrammarExprs.Binary.new()
		expr.init(left_expr, operator, right)

	return expr


func _unary():
	if _match([ESCTokenType.TokenType.BANG, ESCTokenType.TokenType.NOT, ESCTokenType.TokenType.MINUS]):
		var operator: ESCToken = _previous()
		var right: ESCGrammarExpr = _unary()

		var ret = ESCGrammarExprs.Unary.new()
		ret.init(operator, right)
		return ret

	return _contains()


func _contains():
	var expr = _is_checking()

	if expr is ESCParseError:
		return expr

	if _match(ESCTokenType.TokenType.IN):
		var in_token: ESCToken = _previous()

		var consume = _consume(ESCTokenType.TokenType.INVENTORY, "Expected 'inventory' after 'in'.")

		if consume is ESCParseError:
			return consume

		var ret = ESCGrammarExprs.InInventory.new()
		ret.init(expr)
		return ret

	return expr


func _is_checking():
	var expr = _call()

	if expr is ESCParseError:
		return expr

	if _match(ESCTokenType.TokenType.IS):
		var in_token: ESCToken = _previous()

		if _match(ESCTokenType.TokenType.ACTIVE):
			var ret = ESCGrammarExprs.Is.new()
			ret.init(expr, null, _previous())
			return ret

		var state_expr = _expression()

		if state_expr is ESCParseError:
			return state_expr

		var ret = ESCGrammarExprs.Is.new()
		ret.init(expr, state_expr, null)
		return ret

	return expr


func _call():
	var expr = _primary()

	if expr is ESCParseError:
		return expr

	while true:
		if _match(ESCTokenType.TokenType.LEFT_PAREN):
			expr = _finish_call(expr)

			if expr is ESCParseError:
				return expr
		else:
			break

	return expr


func _finish_call(callee: ESCGrammarExpr):
	var args: Array = []
	var to_return = null

	if not _check(ESCTokenType.TokenType.RIGHT_PAREN):
		var done: bool = false

		while not done:
			if args.size() >= 255:
				return _error(_peek(), "Can't have more than 255 arguments.")

			var expr = _expression()

			if expr is ESCParseError:
				return expr

			args.append(expr)

			done = not _match(ESCTokenType.TokenType.COMMA)
			#done = _peek().get_type() == ESCTokenType.TokenType.NEWLINE

	var paren = _consume(ESCTokenType.TokenType.RIGHT_PAREN, "Expect ')' after arguments.")

	if paren is ESCParseError:
		return paren

	#if paren.get_type() != ESCTokenType.TokenType.NEWLINE:
	#	return _error(ESCTokenType.TokenType.NEWLINE, "Expect NEWLINE after arguments.")

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

		var paren = _consume(
			ESCTokenType.TokenType.RIGHT_PAREN,
			"Expect ')' after expression."
		)

		if paren is ESCParseError:
			return paren

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


func _global_declaration() -> ESCGrammarStmt:
	var name = _consume(ESCTokenType.TokenType.IDENTIFIER, "Expect global variable name.")

	var initializer: ESCGrammarExpr = null

	if _match(ESCTokenType.TokenType.EQUAL):
		initializer = _expression()

	_consume(ESCTokenType.TokenType.NEWLINE, "Expect newline after global variable declaration.")

	var ret = ESCGrammarStmts.Global.new()
	ret.init(name, initializer)
	return ret


func _at_end() -> bool:
	return _peek().get_type() == ESCTokenType.TokenType.EOF


func _peek() -> ESCToken:
	return _tokens[_current]


func _match(token_types) -> bool:
	if not token_types is Array:
		token_types = [token_types]

	for type in token_types:
		if _check(type):
			_advance()
			return true

	return false


func _match_in_order(token_types) -> bool:
	if not token_types is Array:
		token_types = [token_types]

	var start := _current

	for type in token_types:
		if not _check(type):
			_current = start
			return false

		_advance()

	return true


func _consume(token_type, message: String):
	if _check(token_type):
		return _advance()

	return _error(_peek(), message)


func _check(token_types) -> bool:
	if not token_types is Array:
		token_types = [token_types]

	if _at_end():
		return false

	for type in token_types:
		if _peek().get_type() == type:
			return true

	return false


# This turns the parser into an LL(2).
func _check_next(token_types) -> bool:
	if not token_types is Array:
		token_types = [token_types]

	if _at_end():
		return false

	_current += 1

	if _at_end():
		_current -= 1
		return false

	for type in token_types:
		if _peek().get_type() == type:
			_current -= 1
			return true

	_current -= 1

	return false


func _previous() -> ESCToken:
	return _tokens[_current - 1]


func _second_previous() -> ESCToken:
	return _tokens[_current - 2]


func _advance() -> ESCToken:
	if not _at_end():
		_current += 1

	return _previous()


func _error(token: ESCToken, message: String) -> ESCParseError:
	_compiler.had_error = true
	var source: String = token.get_filename() if not token.get_filename().is_empty() else token.get_source()

	ESCSafeLogging.log_warn(self, "%s: Line %s at '%s': %s" % [source, token.get_line(), token.get_lexeme(), message])

	return ESCParseError.new()


func _synchronize() -> void:
	if _check(ESCTokenType.TokenType.DEDENT):
		return

	_advance()

	while not _at_end():
		if _previous().get_type() == ESCTokenType.TokenType.NEWLINE \
			or _previous().get_type() == ESCTokenType.TokenType.DEDENT:
			return

		match _peek().get_type():
			ESCTokenType.TokenType.COLON,\
			ESCTokenType.TokenType.GLOBAL,\
			ESCTokenType.TokenType.VAR,\
			ESCTokenType.TokenType.IF,\
			ESCTokenType.TokenType.WHILE,\
			ESCTokenType.TokenType.PASS,\
			ESCTokenType.TokenType.STOP,\
			ESCTokenType.TokenType.QUESTION_BANG,\
			ESCTokenType.TokenType.BREAK,\
			ESCTokenType.TokenType.DONE,\
			ESCTokenType.TokenType.RETURN:
				return

		_advance()
