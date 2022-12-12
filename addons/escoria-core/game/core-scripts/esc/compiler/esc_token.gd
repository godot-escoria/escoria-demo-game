extends Reference
class_name ESCToken


var _tokenType: int # ESCScanner.TokenType enum
var _lexeme: String
var _literal
var _line: int


func init(tokenType: int, lexeme: String, literal, line: int) -> void:
	_tokenType = tokenType
	_lexeme = lexeme
	_literal = literal
	_line = line


func get_type() -> int:
	return _tokenType


func get_literal():
	return _literal


func _to_string() -> String:
	return ESCTokenType.get_token_type_name(_tokenType) + " " + str(_lexeme) + " " + (str(_literal) if _literal else "")
