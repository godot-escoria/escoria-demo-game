extends Reference
class_name ESCToken


var _tokenType: int setget ,get_type # ESCScanner.TokenType enum
var _lexeme: String setget ,get_lexeme
var _literal setget ,get_literal
var _line: int setget ,get_line
var _source: String setget set_source, get_source


func init(tokenType: int, lexeme: String, literal, source: String, line: int) -> void:
	_tokenType = tokenType
	_lexeme = lexeme
	_literal = literal
	_source = source
	_line = line


func set_source(value: String) -> void:
	_source = value


func get_source() -> String:
	return _source


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
