# GdUnit generated TestSuite
class_name ESCParserTest
extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")


func test_done_statement_does_not_consume_tokens_on_partial_match() -> void:
	# This fixture is intentionally valid up to the dialog option body:
	# `done` is in a dialog context, but `done x` is invalid because the parser
	# only accepts `done` followed immediately by a newline.
	var source := _load_fixture("done_partial_match.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("done_partial_match.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var done_index := _find_token_index(tokens, ESCTokenType.TokenType.DONE)
	var print_index := _find_token_index(tokens, ESCTokenType.TokenType.IDENTIFIER, "print")
	assert_int(done_index).is_greater_equal(0)
	assert_int(print_index).is_greater_equal(0)

	# Jump directly to the `done` token so this test exercises the statement
	# parser in isolation. We also force dialog context because `done` is only
	# legal inside dialogs.
	parser._current = done_index
	parser._dialog_level = 1

	var statement = parser._statement()

	# We expect a parse error, but we specifically do not want the parser to
	# consume the `done` token before it discovers that the following token is
	# not a newline. If it advances here, later recovery code starts from the
	# wrong token and can corrupt the remaining parse.
	assert_object(statement).is_instanceof(ESCParseError)
	assert_bool(compiler.had_error).is_true()
	assert_int(parser._current).is_equal(done_index)
	assert_int(parser._peek().get_type()).is_equal(ESCTokenType.TokenType.DONE)
	assert_int(tokens[print_index].get_type()).is_equal(ESCTokenType.TokenType.IDENTIFIER)
	assert_str(tokens[print_index].get_lexeme()).is_equal("print")

	# Tightening the regression: the next statement must still be present in the
	# token stream after the failed `done` parse attempt. This protects against
	# accidental over-consumption beyond the failing statement.
	assert_int(_find_token_index_after(tokens, parser._current, ESCTokenType.TokenType.IDENTIFIER, "print")).is_equal(print_index)


func test_parser_synchronizes_after_invalid_done_and_keeps_following_event() -> void:
	# This fixture places an invalid `done` at the start of an event body and
	# then follows it with a valid statement and a second event. The purpose is
	# to verify parser recovery at ASHES statement and event boundaries.
	var source := _load_fixture("synchronize_after_invalid_done.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("synchronize_after_invalid_done.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	# The parser should report an error for `done x`, but it should still recover
	# well enough to continue parsing later declarations. In particular, the
	# following event `:second` must survive recovery.
	assert_bool(compiler.had_error).is_true()
	assert_int(statements.size()).is_greater_equal(2)
	assert_object(statements[0]).is_not_null()
	assert_object(statements[1]).is_not_null()
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")


func test_parser_synchronizes_after_invalid_if_and_keeps_following_event() -> void:
	# This fixture uses a malformed `if` statement inside an event body. The
	# missing colon forces a real statement parse error after the parser has
	# already committed to the `if` branch. Recovery must still preserve the
	# following top-level event declaration.
	var source := _load_fixture("synchronize_after_invalid_if.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("synchronize_after_invalid_if.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	assert_bool(compiler.had_error).is_true()
	assert_int(statements.size()).is_greater_equal(2)
	assert_object(statements[0]).is_not_null()
	assert_object(statements[1]).is_not_null()
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")


func test_dialog_option_missing_right_square_returns_parse_error() -> void:
	# This fixture omits the closing `]` from a dialog option predicate. The
	# parser should report a parse error here rather than silently building a
	# malformed dialog option node and continuing as if the condition was valid.
	# Recovery should still preserve the following top-level event declaration.
	var source := _load_fixture("dialog_option_missing_right_square.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("dialog_option_missing_right_square.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	assert_bool(compiler.had_error).is_true()
	assert_int(statements.size()).is_greater_equal(2)
	assert_object(statements[0]).is_not_null()
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")
	assert_object(statements[1]).is_not_null()
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")


func test_grouping_missing_right_paren_returns_parse_error() -> void:
	# This fixture omits the closing `)` from a grouped expression inside a
	# function call. The parser must not silently accept the grouping and build
	# a malformed AST; it should report the error and still preserve the
	# following event declaration after recovery.
	var source := _load_fixture("grouping_missing_right_paren.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("grouping_missing_right_paren.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	assert_bool(compiler.had_error).is_true()
	assert_int(statements.size()).is_greater_equal(2)
	assert_object(statements[0]).is_not_null()
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")
	assert_object(statements[1]).is_not_null()
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")


func test_var_grouping_missing_right_paren_returns_parse_error() -> void:
	# This fixture omits the closing `)` from a grouped expression in a variable
	# initializer. Unlike the call-expression regression above, this path goes
	# straight through `_primary()`, so the parser must reject the malformed
	# grouping instead of silently constructing a `Grouping` node.
	var source := _load_fixture("var_grouping_missing_right_paren.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("var_grouping_missing_right_paren.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	assert_bool(compiler.had_error).is_true()
	assert_int(statements.size()).is_greater_equal(2)
	assert_object(statements[0]).is_not_null()
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")
	assert_object(statements[1]).is_not_null()
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")


func test_var_declaration_missing_newline_returns_parse_error() -> void:
	# This fixture continues a variable declaration onto the same line with a
	# second statement. The parser should not silently accept the declaration
	# when the required trailing newline is missing, and recovery should still
	# preserve the following event.
	var source := _load_fixture("var_missing_newline.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("var_missing_newline.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	assert_bool(compiler.had_error).is_true()
	assert_int(statements.size()).is_greater_equal(2)
	assert_object(statements[0]).is_not_null()
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")
	assert_object(statements[1]).is_not_null()
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")


func test_while_error_does_not_leak_loop_level_into_later_event() -> void:
	# This fixture forces `_while_statement()` to fail after incrementing
	# `_loop_level`. The later `break` in `:second` is top-level within that
	# event body and must still be rejected. If the loop counter leaks across the
	# error path, the parser will incorrectly accept it as a valid `Break`.
	var source := _load_fixture("while_error_then_top_level_break.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("while_error_then_top_level_break.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	assert_bool(compiler.had_error).is_true()
	assert_int(statements.size()).is_greater_equal(3)
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")
	assert_object(statements[2]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[2].get_event_name()).is_equal("third")

	var second_body: Array = statements[1].get_body().get_statements()
	assert_int(second_body.size()).is_equal(0)


func test_dialog_error_does_not_leak_dialog_level_into_later_event() -> void:
	# This fixture forces `_dialog_statement()` to fail after incrementing
	# `_dialog_level`. The later `done` in `:second` is top-level within that
	# event body and must still be rejected. If the dialog counter leaks across
	# the error path, the parser will incorrectly accept it as a valid `Done`.
	var source := _load_fixture("dialog_error_then_top_level_done.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("dialog_error_then_top_level_done.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	assert_bool(compiler.had_error).is_true()
	assert_int(statements.size()).is_greater_equal(3)
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")
	assert_object(statements[2]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[2].get_event_name()).is_equal("third")

	var second_body: Array = statements[1].get_body().get_statements()
	assert_int(second_body.size()).is_equal(0)


func test_happy_path_full_language_fixture_parses_without_errors() -> void:
	# This smoke fixture exercises a broad cross-section of ASHES syntax on the
	# parser happy path: event flags, targets, globals, locals, branching,
	# looping, built-ins, dialog, nested dialog, conditional dialog options,
	# `break`, `done`, `in inventory`, `is active`, and `is "state"`.
	var source := _load_fixture("happy_path_full_language.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("happy_path_full_language.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()

	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(2)
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("setup")
	assert_int(statements[0].get_num_statements_in_block()).is_equal(6)
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("look")
	assert_str(statements[1].get_target_name()).is_equal("worker")
	assert_int(statements[1].get_num_statements_in_block()).is_equal(3)


func test_keyword_prefixed_names_scan_as_identifiers() -> void:
	# ASHES keywords should only match on exact identifier text. Names that
	# merely start with keyword text must still scan as ordinary identifiers.
	var source := _load_fixture("identifier_keyword_prefixes.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("identifier_keyword_prefixes.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")
	var statements := parser.parse()

	assert_bool(compiler.had_error).is_false()
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.IDENTIFIER, "breakfast")).is_greater_equal(0)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.IDENTIFIER, "donee")).is_greater_equal(0)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.IDENTIFIER, "elseify")).is_greater_equal(0)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.IDENTIFIER, "notable")).is_greater_equal(0)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.BREAK, "break")).is_equal(-1)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.DONE, "done")).is_equal(-1)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.ELSE, "else")).is_equal(-1)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.NOT, "not")).is_equal(-1)
	assert_int(statements.size()).is_equal(1)
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")


func test_hyphenated_global_identifier_scans_as_single_identifier() -> void:
	# `$`-prefixed global-ID shorthand may contain hyphens, but ordinary `-`
	# characters must still scan as subtraction operators outside that prefix.
	var source := _load_fixture("hyphenated_global_identifier.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("hyphenated_global_identifier.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")
	var statements := parser.parse()

	assert_bool(compiler.had_error).is_false()
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.IDENTIFIER, "$closet-door")).is_greater_equal(0)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.MINUS, "-")).is_greater_equal(0)
	assert_int(_find_token_index(tokens, ESCTokenType.TokenType.NUMBER, "1")).is_greater_equal(0)
	assert_int(statements.size()).is_equal(1)
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")


func test_blank_lines_in_nested_blocks_do_not_break_later_events() -> void:
	# Blank lines inside nested blocks should not corrupt INDENT/DEDENT handling.
	# The parser must still recover the later top-level event after the nested
	# block ends.
	var source := _load_fixture("blank_lines_in_nested_blocks.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("blank_lines_in_nested_blocks.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")
	var statements := parser.parse()

	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(2)
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")


func test_blank_lines_before_dedent_do_not_hide_block_termination() -> void:
	# Blank lines immediately before a block-closing dedent should not be eaten
	# in a way that hides the dedent from `_block()`. The outer statement after
	# the nested block, plus the later top-level event, must still parse.
	var source := _load_fixture("blank_lines_before_dedent.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("blank_lines_before_dedent.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")
	var statements := parser.parse()

	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(2)
	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[0].get_event_name()).is_equal("test")
	assert_object(statements[1]).is_instanceof(ESCGrammarStmts.Event)
	assert_str(statements[1].get_event_name()).is_equal("second")
	assert_int(statements[0].get_num_statements_in_block()).is_equal(2)


func _load_fixture(name: String) -> String:
	return FileAccess.get_file_as_string(_fixture_path(name))


func _fixture_path(name: String) -> String:
	return "res://addons/escoria-core/testing/ashes/parser/fixtures/%s" % name


func _find_token_index(tokens: Array, token_type: int, lexeme: String = "") -> int:
	for index in range(tokens.size()):
		var token = tokens[index]
		if token.get_type() == token_type and (lexeme.is_empty() or token.get_lexeme() == lexeme):
			return index

	return -1


func _find_token_index_after(tokens: Array, current_index: int, token_type: int, lexeme: String = "") -> int:
	for index in range(current_index + 1, tokens.size()):
		var token = tokens[index]
		if token.get_type() == token_type and (lexeme.is_empty() or token.get_lexeme() == lexeme):
			return index

	return -1
