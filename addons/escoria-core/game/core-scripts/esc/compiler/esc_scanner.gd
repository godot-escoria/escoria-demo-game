## ASHES language scanner.
##
## This is the first link in the ASHES compiler toolchain, and takes in ASHES 
## script as text in order to provide a list of tokens to be handled by the 
## ASHES parser.
extends RefCounted
class_name ESCScanner


var _tokens: Array = []

var _keywords: Dictionary
var _start: int = 0
var _current: int = 0
var _line: int = 1
var _at_start_of_line: bool = true
var _empty_line: bool = false
var _indent_level: int = 0

var _escape_chars: Array = []

var _source: String:
	set = set_source
var _filename: String:
	set = set_filename,
	get = get_filename

var _alpha_regex: RegEx
var _digit_regex: RegEx
var _alphanumeric_regex: RegEx

var _indent_level_stack: Array


func _init():
	_keywords["active"] = ESCTokenType.TokenType.ACTIVE
	_keywords["and"] = ESCTokenType.TokenType.AND
	_keywords["break"] = ESCTokenType.TokenType.BREAK
	_keywords["done"] = ESCTokenType.TokenType.DONE
	_keywords["elif"] = ESCTokenType.TokenType.ELIF
	_keywords["else"] = ESCTokenType.TokenType.ELSE
	_keywords["false"] = ESCTokenType.TokenType.FALSE
	_keywords["global"] = ESCTokenType.TokenType.GLOBAL
	_keywords["if"] = ESCTokenType.TokenType.IF
	_keywords["in"] = ESCTokenType.TokenType.IN
	_keywords["inventory"] = ESCTokenType.TokenType.INVENTORY
	_keywords["is"] = ESCTokenType.TokenType.IS
	_keywords["nil"] = ESCTokenType.TokenType.NIL
	_keywords["not"] = ESCTokenType.TokenType.NOT
	_keywords["or"] = ESCTokenType.TokenType.OR
	_keywords["pass"] = ESCTokenType.TokenType.PASS
	_keywords["stop"] = ESCTokenType.TokenType.STOP
	_keywords["true"] = ESCTokenType.TokenType.TRUE
	_keywords["var"] = ESCTokenType.TokenType.VAR
	_keywords["while"] = ESCTokenType.TokenType.WHILE

	_escape_chars.append('"')

	_alpha_regex = RegEx.new()
	_alpha_regex.compile("[a-zA-Z_\\$]")

	_digit_regex = RegEx.new()
	_digit_regex.compile("[0-9]")

	_alphanumeric_regex = RegEx.new()
	_alphanumeric_regex.compile("[a-zA-Z0-9_\\$]")

	_indent_level_stack.push_front(0)


## Sets the ASHES source as a string. This is the source that will be scanned and turned into tokens.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |source|`String`|Raw ASHES source text to tokenize.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_source(source: String) -> void:
	# If we don't have a newline terminator, then we add one to be safe.
	if not source.ends_with("\n"):
		source += "\n"

	_source = source


## Sets the path of the file containing the source to be scanned.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |filename|`String`|Path associated with the source (used for error reporting).|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_filename(filename: String) -> void:
	_filename = filename


## The path of the file containing the source to be scanned.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the path of the file containing the source to be scanned. (`String`)
func get_filename() -> String:
	return _filename


## Entry point for the scanner. Begins scanning the source and returns an array of tokens corresponding to the source. `set_source` must be called prior to calling this method.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `Array` value. (`Array`)
func scan_tokens() -> Array:
	while not _at_end():
		_start = _current
		_scan_token()

	# Generate a DEDENT token for each indent level > 0 left on the stack
	while _indent_level_stack.pop_front() > 0:
		_add_token(ESCTokenType.TokenType.DEDENT, null)

	var token: ESCToken = ESCToken.new()
	token.init(ESCTokenType.TokenType.EOF, "", null, _source, _line, _filename)
	_tokens.append(token)

	return _tokens


func _scan_token():
	var c: String = _advance()

	# We need to check for entirely empty/blank lines, so do some lookahead stuff.
	if _at_start_of_line:
		var line_indent_level: int = 0
		var done: bool = false

		while not done:
			if c == ' ':
				_start = _current
				c = _advance()
			elif c == '\t':
				line_indent_level += 1
				_start = _current
				c = _advance()
			else:
				done = true

		match c:
			'#', '\r', '\n':
				_empty_line = true
			_:
				_empty_line = false

		if not _empty_line:
			_check_indent(line_indent_level)

		_at_start_of_line = false

	match c:
		'(':
			_add_token(ESCTokenType.TokenType.LEFT_PAREN, null)
		')':
			_add_token(ESCTokenType.TokenType.RIGHT_PAREN, null)
		'[':
			_add_token(ESCTokenType.TokenType.LEFT_SQUARE, null)
		']':
			_add_token(ESCTokenType.TokenType.RIGHT_SQUARE, null)
		',':
			_add_token(ESCTokenType.TokenType.COMMA, null)
		'.':
			_add_token(ESCTokenType.TokenType.DOT, null)
		'-':
			_add_token(ESCTokenType.TokenType.MINUS, null)
		'+':
			_add_token(ESCTokenType.TokenType.PLUS, null)
		'*':
			_add_token(ESCTokenType.TokenType.STAR, null)
		':':
			_add_token(ESCTokenType.TokenType.COLON, null)
		'/':
			_add_token(ESCTokenType.TokenType.SLASH, null)
		'|':
			_add_token(ESCTokenType.TokenType.PIPE, null)
		'?':
			_add_token(ESCTokenType.TokenType.QUESTION_BANG if _match('!') else ESCTokenType.TokenType.QUESTION, null)
		'#':
			# the rest of the line is a comment
			while _peek() != '\n' and not _at_end():
				_advance()

		'\r', '\n':
			if not _empty_line:
				_add_token(ESCTokenType.TokenType.NEWLINE, null)

			_line += 1
			_at_start_of_line = true
		'!':
			if _match('='):
				_add_token(ESCTokenType.TokenType.BANG_EQUAL, null)
			elif _match('?'):
				_add_token(ESCTokenType.TokenType.BANG_QUESTION, null)
			else:
				_add_token(ESCTokenType.TokenType.BANG, null)
		'=':
			_add_token(ESCTokenType.TokenType.EQUAL_EQUAL if _match('=') else ESCTokenType.TokenType.EQUAL, null)
		'<':
			_add_token(ESCTokenType.TokenType.LESS_EQUAL if _match('=') else ESCTokenType.TokenType.LESS, null)
		'>':
			_add_token(ESCTokenType.TokenType.GREATER_EQUAL if _match('=') else ESCTokenType.TokenType.GREATER, null)

		' ', '\t':
			pass

		'"':
			_string()

		_:
			if _is_digit(c):
				_number()
			elif _is_alpha(c):
				_identifier()
			else:
				_error(_line, "Unexpected character: %s" % c)


func _check_indent(indent_level: int) -> void:
	if indent_level > _indent_level_stack.front():
		_indent_level_stack.push_front(indent_level)
		_add_token(ESCTokenType.TokenType.INDENT, null)
	elif indent_level < _indent_level_stack.front():
		while _indent_level_stack.front() > indent_level:
			_indent_level_stack.pop_front()
			_add_token(ESCTokenType.TokenType.DEDENT, null)

		if _indent_level_stack.front() != indent_level:
			_error(_line, "Inconsistent indent.")


func _is_digit(c: String) -> bool:
	return _digit_regex.search(c) != null


func _is_alpha(c: String) -> bool:
	return _alpha_regex.search(c) != null


func _is_alphanumeric(c: String) -> bool:
	return _alphanumeric_regex.search(c) != null


func _identifier() -> void:
	while _is_alphanumeric(_peek()):
		_advance()

	var text: String = _source.substr(_start, _current - _start)
	var type = _keywords.get(text)

	if not type:
		type = ESCTokenType.TokenType.IDENTIFIER

	_add_token(type, null)


func _string() -> void:
	while (_is_escape_char() or _peek() != '"') and not _at_end():
		if _peek() == '\n':
			_line += 1
		_advance()

	if _at_end():
		_error(_line, "Unterminated string.")
		return

	# Closing "
	_advance()

	# Trim surrounding quotes
	var value: String = _source.substr(_start + 1, (_current - 1) - (_start + 1))

	# Deal with escape chars
	for c in _escape_chars:
		value = value.replace("\\" + c, c)

	_add_token(ESCTokenType.TokenType.STRING, value)


func _number() -> void:
	while _is_digit(_peek()):
		_advance()

	# Fraction part?
	if _peek() == '.' and _is_digit(_peek_next()):
		_advance()

		while _is_digit(_peek()):
			_advance()

	_add_token(ESCTokenType.TokenType.NUMBER, _source.substr(_start, _current - _start).to_float())


func _is_escape_char() -> bool:
	if _peek() == '\\' and _peek_next() in _escape_chars:
		_advance()
		return true

	return false


# TODO: Move error reporting up when compiler is updated.
func _error(line: int, message: String) -> void:
	ESCSafeLogging.log_error(self, "[Line %s]: %s" % [line, message])


func _match(expected: String) -> bool:
	if _at_end():
		return false;

	if _source[_current] != expected:
		return false

	_current += 1

	return true


func _peek() -> String:
	if _at_end():
		return "\\0"

	return _source[_current]


func _peek_next() -> String:
	if _current + 1 >= _source.length():
		return '\\0'

	return _source[_current + 1]


func _at_end() -> bool:
	return _current >= _source.length()


func _advance() -> String:
	var c: String = _source[_current]
	_current += 1
	return c


func _rewind() -> void:
	_current -= 1

	if _current <= 0:
		_current = 0


func _add_token(type: int, literal) -> void:
	var text: String = ""

	if not type in [ESCTokenType.TokenType.INDENT, ESCTokenType.TokenType.DEDENT]:
		text = _source.substr(_start, _current - _start)

	var token: ESCToken = ESCToken.new()
	token.init(type, text, literal, _source, _line, _filename)
	_tokens.append(token)
