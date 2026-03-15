# GdUnit generated TestSuite
class_name ESCParserTest
extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")


func test_done_statement_does_not_consume_tokens_on_partial_match() -> void:
	# This fixture is intentionally valid up to the dialog option body:
	# `done` is in a dialog context, but `done x` is invalid because the parser
	# only accepts `done` followed immediately by a newline.
	var source := ":test\n\t?!\n\t\t- \"Option\"\n\t\t\tdone x\n\t\t\tprint(\"after\")\n"
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename("res://tests/done_partial_match.esc")

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
