extends RefCounted
class_name ESCToken


var _tokenType: int: # ESCScanner.TokenType enum
	get = get_type 
var _lexeme: String:
	get = get_lexeme
var _literal:
	get = get_literal
var _line: int:
	get = get_line
var _source: String:
	get = get_source,
	set = set_source
var _filename: String:
	get = get_filename


func init(tokenType: int, lexeme: String, literal, source: String, line: int, filename: String) -> void:
	_tokenType = tokenType
	_lexeme = lexeme
	_literal = literal
	_source = source
	_line = line
	_filename = filename


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


func get_filename() -> String:
	return _filename


func _to_string() -> String:
	return ESCTokenType.get_token_type_name(_tokenType) + " " + str(_lexeme) + " " + (str(_literal) if _literal else "")
