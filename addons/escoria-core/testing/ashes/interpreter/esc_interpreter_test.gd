# GdUnit generated TestSuite
class_name ESCInterpreterTest
extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")

var _terminate_on_errors_before: bool
var _command_directories_before: PackedStringArray
var _dialog_player_before


class DialogPlayerDouble extends ESCDialogPlayer:
	var _choice_indexes: Array = []
	var _choices_consumed: int = 0


	func _init(choice_indexes: Array = []):
		_choice_indexes = choice_indexes.duplicate()


	func start_dialog_choices(dialog: ESCDialog, type: String = "simple"):
		# Mirror the real dialog player closely enough for interpreter tests:
		# only valid options are choosable, and scripted indexes deterministically
		# drive nested dialog flows without needing UI interaction.
		var valid_options: Array = []
		for option in dialog.options:
			if option.is_valid():
				valid_options.append(option)

		var choice_index := 0
		if not _choice_indexes.is_empty():
			choice_index = int(_choice_indexes.pop_front())
			_choices_consumed += 1

		call_deferred("_emit_choice", valid_options[choice_index] if choice_index < valid_options.size() else null)


	func _emit_choice(option) -> void:
		option_chosen.emit(option)


	func get_choices_consumed() -> int:
		return _choices_consumed


	func get_remaining_choices() -> int:
		return _choice_indexes.size()


func before() -> void:
	# Interpreter tests intentionally trigger runtime errors in a few cases, so
	# they disable terminate-on-error and install a test-only command directory.
	# The dialog player is also replaced on demand by a deterministic test
	# double so dialog execution can run headlessly.
	_terminate_on_errors_before = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.TERMINATE_ON_ERRORS
	)
	_command_directories_before = PackedStringArray(
		ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.COMMAND_DIRECTORIES
		)
	)
	_dialog_player_before = escoria.get("dialog_player")

	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.TERMINATE_ON_ERRORS,
		false
	)
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.COMMAND_DIRECTORIES,
		PackedStringArray([
			"res://addons/escoria-core/testing/ashes/interpreter/support/commands"
		] + Array(_command_directories_before))
	)
	escoria.command_registry.registry.clear()
	escoria.set("dialog_player", null)


func after() -> void:
	# Restore shared Escoria settings and globals so each test starts from the
	# same baseline and does not leak command registry or dialog-player state.
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.TERMINATE_ON_ERRORS,
		_terminate_on_errors_before
	)
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.COMMAND_DIRECTORIES,
		_command_directories_before
	)
	escoria.command_registry.registry.clear()
	escoria.set("dialog_player", _dialog_player_before)


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


func test_print_with_zero_arguments_does_not_native_crash() -> void:
	# This fixture calls the builtin `print()` with zero arguments. The current
	# implementation only rejects calls with more than one argument, so this
	# test captures the actual runtime behavior before we decide on a fix.
	var source := _load_fixture("print_zero_args.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("print_zero_args.esc"))

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

	interpreter.cleanup()


func test_print_with_two_arguments_does_not_native_crash() -> void:
	# This fixture calls the builtin `print()` with too many arguments. The
	# builtin should reject the call cleanly and avoid any native runtime error.
	var source := _load_fixture("print_two_args.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("print_two_args.esc"))

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

	interpreter.cleanup()


func test_stop_in_nested_block_prevents_later_statements() -> void:
	# `stop` should unwind the current event immediately, even when it is issued
	# from inside a nested block. The later assignment must therefore never run.
	var outcome := await _interpret_fixture("stop_nested_block.esc")
	var globals: Dictionary = outcome.globals
	assert_bool(globals.has("result")).is_true()
	assert_float(float(globals["result"])).is_equal(0.0)


func test_done_in_nested_dialog_block_prevents_later_statements() -> void:
	# `done` should conclude the current dialog from inside a nested block, but
	# it must not abort the rest of the event. The assignment after the dialog
	# should still execute, proving the dialog exits cleanly without leaking a
	# control-flow sentinel to the enclosing event body.
	var outcome := await _interpret_fixture(
		"done_nested_block_in_dialog.esc",
		[0]
	)
	var globals: Dictionary = outcome.globals
	assert_bool(globals.has("result")).is_true()
	assert_float(float(globals["result"])).is_equal(1.0)


func test_break_one_returns_to_parent_dialog_level() -> void:
	# `break 1` should move dialog control back up one level, not continue the
	# remainder of the current outer option body. The scripted choice sequence
	# must therefore consume a third outer-dialog choice after the nested break;
	# if the dialog ends early instead, the final string alone is ambiguous.
	var outcome := await _interpret_fixture(
		"nested_dialog_break_one.esc",
		[0, 0, 1]
	)
	assert_bool(outcome.globals.has("result")).is_true()
	assert_str(String(outcome.globals["result"])).is_equal("start-done")
	assert_int(int(outcome.dialog_choices_consumed)).is_equal(3)
	assert_int(int(outcome.remaining_dialog_choices)).is_equal(0)


func test_done_exits_entire_nested_dialog_tree() -> void:
	# `done` should conclude the entire dialog from any nesting depth. After the
	# nested choice issues `done`, the outer option body must not continue and
	# the outer dialog must not be shown again. Execution should resume only
	# after the dialog statement, so the final value should reflect the initial
	# value plus the post-dialog append.
	var outcome := await _interpret_fixture(
		"done_exits_entire_nested_dialog.esc",
		[0, 0]
	)
	var globals: Dictionary = outcome.globals
	assert_bool(globals.has("result")).is_true()
	assert_str(String(globals["result"])).is_equal("start-done")


func test_break_two_exits_two_dialog_levels() -> void:
	# `break 2` from the innermost dialog should move back up two dialog levels
	# to the outermost dialog in this fixture shape. As with `break 1`, the test
	# also verifies that the final scripted outer choice was actually consumed,
	# which proves the outer dialog stayed alive after the nested unwind.
	var outcome := await _interpret_fixture(
		"break_two_exits_two_dialog_levels.esc",
		[0, 0, 0, 1]
	)
	assert_bool(outcome.globals.has("result")).is_true()
	assert_str(String(outcome.globals["result"])).is_equal("start-done")
	assert_int(int(outcome.dialog_choices_consumed)).is_equal(4)
	assert_int(int(outcome.remaining_dialog_choices)).is_equal(0)


func test_stop_in_dialog_option_prevents_later_event_statements() -> void:
	# `stop` issued from a dialog option should abort the entire event, not just
	# the current dialog. The assignment after the dialog must therefore never run.
	var outcome := await _interpret_fixture(
		"stop_in_dialog_option.esc",
		[0]
	)
	assert_bool(outcome.globals.has("result")).is_true()
	assert_float(float(outcome.globals["result"])).is_equal(0.0)


func test_delayed_command_in_dialog_option_preserves_ordering() -> void:
	# A blocking command inside a dialog option must complete before the option
	# body resumes and before execution continues after the dialog. If it does
	# not block correctly, the final append would observe `unset` instead of the
	# command-written value.
	var outcome := await _interpret_fixture(
		"delayed_command_in_dialog_option.esc",
		[0]
	)
	assert_bool(outcome.globals.has("result")).is_true()
	assert_str(String(outcome.globals["result"])).is_equal("cmd-after")


func test_immediate_command_preserves_statement_ordering() -> void:
	# A synchronous command should complete before the next statement runs. The
	# trailing assignment observes the command's mutation and appends to it.
	var outcome := await _interpret_fixture("immediate_command_ordering.esc")
	var globals: Dictionary = outcome.globals
	assert_bool(globals.has("result")).is_true()
	assert_str(String(globals["result"])).is_equal("cmd-after")


func test_delayed_command_preserves_statement_ordering() -> void:
	# An asynchronous command must also block statement sequencing. If the
	# interpreter failed to await it, the trailing assignment would append to the
	# pre-command value instead of the command-written one.
	var outcome := await _interpret_fixture("delayed_command_ordering.esc")
	var globals: Dictionary = outcome.globals
	assert_bool(globals.has("result")).is_true()
	assert_str(String(globals["result"])).is_equal("cmd-after")


func _interpret_fixture(name: String, dialog_choices: Array = []) -> Dictionary:
	# Shared interpreter harness for fixture-based tests. This intentionally
	# runs the full scan -> parse -> resolve -> interpret pipeline so the tests
	# cover the real runtime path rather than isolated visitor calls.
	var source := _load_fixture(name)
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path(name))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()
	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(1)

	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	resolver.resolve(statements)
	var dialog_player = null

	if not dialog_choices.is_empty():
		# Install a temporary deterministic dialog player only for tests that
		# need scripted choices, then clean it up afterward to avoid orphan nodes.
		dialog_player = DialogPlayerDouble.new(dialog_choices)
		escoria.set("dialog_player", dialog_player)

	await interpreter.interpret(statements)

	var globals := interpreter.get_global_values().duplicate(true)
	var dialog_choices_consumed := 0
	var remaining_dialog_choices := 0

	if dialog_player:
		dialog_choices_consumed = dialog_player.get_choices_consumed()
		remaining_dialog_choices = dialog_player.get_remaining_choices()

	interpreter.cleanup()

	if dialog_player:
		escoria.set("dialog_player", null)
		dialog_player.queue_free()

	return {
		"globals": globals,
		"dialog_choices_consumed": dialog_choices_consumed,
		"remaining_dialog_choices": remaining_dialog_choices,
	}


func _load_fixture(name: String) -> String:
	return FileAccess.get_file_as_string(_fixture_path(name))


func _fixture_path(name: String) -> String:
	return "res://addons/escoria-core/testing/ashes/interpreter/fixtures/%s" % name
