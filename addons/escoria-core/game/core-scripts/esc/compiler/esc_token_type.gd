class_name ESCTokenType


enum TokenType {
	INDENT, DEDENT, NEWLINE,

	COLON, DOT, MINUS, PLUS, SLASH, STAR,

	BANG, BANG_EQUAL,
	EQUAL, EQUAL_EQUAL,
	GREATER, GREATER_EQUAL,
	LESS, LESS_EQUAL,

	IDENTIFIER, STRING, NUMBER,

	AND, ELSE, FALSE, IF, NIL, OR, PRINT, TRUE, VAR, WHILE,

	EOF
}


static func get_token_type_name(type: int) -> String:
	return TokenType.keys()[type]
