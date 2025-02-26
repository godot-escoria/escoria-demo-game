extends RefCounted
class_name ESCStaticAnalyzers


var _analyzers = [
	ESCExitSceneScriptAnalyzer.new()
]

var _parsed_statements = []


func _init(parsed_statements: Array) -> void:
	_parsed_statements = parsed_statements


func run() -> void:
	for analyzer in _analyzers:
		analyzer.analyze(_parsed_statements)
		analyzer.print_messages()
