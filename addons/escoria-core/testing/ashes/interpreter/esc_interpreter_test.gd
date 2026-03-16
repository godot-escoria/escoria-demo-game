# GdUnit generated TestSuite
class_name ESCInterpreterTest
extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")

var _terminate_on_errors_before: bool


func before() -> void:
	_terminate_on_errors_before = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.TERMINATE_ON_ERRORS
	)
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.TERMINATE_ON_ERRORS,
		false
	)


func after() -> void:
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.TERMINATE_ON_ERRORS,
		_terminate_on_errors_before
	)


func test_execute_block_restores_scope_after_break() -> void:
	# This fixture creates a nested block-local `x`, exits that block with
	# `break`, and then reads `x` afterward into a global. If `_execute_block()`
	# fails to restore `_environment` on the early return, the later lookup will
	# incorrectly resolve the inner `x` instead of the outer one.
	var source := _load_fixture("block_scope_restores_after_break.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("block_scope_restores_after_break.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()
	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(1)

	var interpreter := ESCInterpreter.new([], {})
	var resolver := ESCResolver.new(interpreter)
	resolver.resolve(statements)

	await interpreter.interpret(statements)

	var globals := interpreter.get_global_values()
	assert_bool(globals.has("result")).is_true()
	assert_float(float(globals["result"])).is_equal(1.0)

	interpreter.cleanup()


func test_invalid_numeric_comparison_does_not_succeed_silently() -> void:
	# This fixture performs an invalid numeric comparison. Invalid numeric
	# operations should log an interpreter error and evaluate to `null` rather
	# than continuing into a native GDScript operator error.
	var source := _load_fixture("invalid_numeric_comparison.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("invalid_numeric_comparison.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()
	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(1)

	var interpreter := ESCInterpreter.new([], {})
	var resolver := ESCResolver.new(interpreter)
	resolver.resolve(statements)

	await interpreter.interpret(statements)

	var globals := interpreter.get_global_values()
	assert_bool(globals.has("result")).is_true()
	assert_bool(globals["result"] == null).is_true()

	interpreter.cleanup()


func _load_fixture(name: String) -> String:
	return FileAccess.get_file_as_string(_fixture_path(name))


func _fixture_path(name: String) -> String:
	return "res://addons/escoria-core/testing/ashes/interpreter/fixtures/%s" % name
