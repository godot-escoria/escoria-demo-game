## Defines all possible token types for ASHES.
##
## Note that this way of representing enums is a holdover from Godot 3.x, and
## should be updated to the Godot 4 paradigm at some point.
class_name ESCTokenType


## An exhaustive list of all token types recognized by ASHES.
enum TokenType {
	INDENT, DEDENT, NEWLINE,

	COLON, COMMA, DOT, LEFT_PAREN, LEFT_SQUARE, RIGHT_PAREN, RIGHT_SQUARE,
	MINUS, PIPE, PLUS, SLASH, STAR,

	BANG, BANG_EQUAL, BANG_QUESTION,
	EQUAL, EQUAL_EQUAL,
	GREATER, GREATER_EQUAL,
	LESS, LESS_EQUAL,
	QUESTION, QUESTION_BANG,

	IDENTIFIER, STRING, NUMBER,

	ACTIVE, AND, BREAK, DONE, ELIF, ELSE, FALSE, GLOBAL, IF, IN, INVENTORY, IS,
	NIL, NOT, OR, PASS, RETURN, STOP, TRUE, VAR, WHILE,

	EOF
}


## Translates a given token type into its name.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |type|`int`|TokenType enumeration value to translate to its name.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `String` value. (`String`)
static func get_token_type_name(type: int) -> String:
	return TokenType.keys()[type]
