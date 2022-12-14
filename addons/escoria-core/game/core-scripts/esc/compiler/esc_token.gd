extends Reference
class_name ESCToken


var _tokenType: int setget ,get_type # ESCScanner.TokenType enum
var _lexeme: String setget ,get_lexeme
var _literal setget ,get_literal
var _line: int setget ,get_line


func init(tokenType: int, lexeme: String, literal, line: int) -> void:
	_tokenType = tokenType
	_lexeme = lexeme
	_literal = literal
	_line = line


func get_type() -> int:
	return _tokenType


func get_literal():
	return _literal


func get_lexeme() -> String:
	return _lexeme


func get_line() -> int:
	return _line


func _to_string() -> String:
	return ESCTokenType.get_token_type_name(_tokenType) + " " + str(_lexeme) + " " + (str(_literal) if _literal else "")
