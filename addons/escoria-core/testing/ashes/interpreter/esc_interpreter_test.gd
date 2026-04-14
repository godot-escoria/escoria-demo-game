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
	var _dialogs_started: Array = []


	func _init(choice_indexes: Array = []):
		_choice_indexes = choice_indexes.duplicate()


	func start_dialog_choices(dialog: ESCDialog, _type: String = "simple"):
		var option_keys: Array = []
		var option_texts: Array = []
		for option in dialog.options:
			option_keys.append(option.translation_key)
			option_texts.append(option.option)

		_dialogs_started.append({
			"avatar": dialog.avatar,
			"timeout": dialog.timeout,
			"timeout_option": dialog.timeout_option,
			"options_size": dialog.options.size(),
			"option_keys": option_keys,
			"option_texts": option_texts
		})

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


	func get_dialogs_started() -> Array:
		return _dialogs_started.duplicate(true)


func before() -> void:
	# Interpreter tests intentionally trigger runtime errors in a few cases, so
	# they disable terminate-on-error and install a test-only command directory.
	# The dialog player is also replaced on demand by a deterministic test
	# double so dialog execution can run headlessly.
	ESCInterpreterFactory.reset_interpreter()
	escoria.event_manager.interrupt([], false)
	escoria.event_manager.clear_event_queue()
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
	ESCInterpreterFactory.reset_interpreter()
	escoria.event_manager.interrupt([], false)
	escoria.event_manager.clear_event_queue()
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


func test_dialog_followup_runs_after_all_options_are_exhausted() -> void:
	# When each option invalidates itself, the dialog should conclude once no
	# valid options remain. Execution must then continue with the statement after
	# the dialog block.
	var outcome := await _interpret_fixture(
		"dialog_exhausted_options_runs_followup.esc",
		[0, 0]
	)
	var globals: Dictionary = outcome.globals
	assert_bool(globals.has("result")).is_true()
	assert_str(String(globals["result"])).is_equal("start-say1-say2-finished")
	assert_bool(bool(globals["option1_is_valid"])).is_false()
	assert_bool(bool(globals["option2_is_valid"])).is_false()
	assert_int(int(outcome.dialog_choices_consumed)).is_equal(2)
	assert_int(int(outcome.remaining_dialog_choices)).is_equal(0)


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


func test_delayed_command_in_loop_preserves_ordering() -> void:
	# A blocking command inside a loop body must finish before the loop can
	# continue to the next statement. The later append therefore proves the
	# delayed command completed before the event resumed after the loop.
	var outcome := await _interpret_fixture("delayed_command_in_loop.esc")
	assert_bool(outcome.globals.has("result")).is_true()
	assert_str(String(outcome.globals["result"])).is_equal("cmd-after")
	assert_bool(outcome.globals.has("count")).is_true()
	assert_float(float(outcome.globals["count"])).is_equal(1.0)


func test_interrupting_delayed_command_stops_event_progress() -> void:
	# Interrupting an in-flight command should stop the surrounding event from
	# resuming normal execution. The command records that it observed the
	# interrupt, and the later append must never run.
	var source := _load_fixture("delayed_command_interrupt.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("delayed_command_interrupt.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()
	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(1)

	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	resolver.resolve(statements)

	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	var event_stmt: ESCGrammarStmts.Event = statements[0]
	interpreter.call_deferred("interpret", statements)
	await escoria.get_tree().create_timer(0.05).timeout
	interpreter.interrupt()
	await event_stmt.finished

	var globals := interpreter.get_global_values()
	assert_bool(globals.has("result")).is_true()
	assert_str(String(globals["result"])).is_equal("start")
	assert_bool(globals.has("was_interrupted")).is_true()
	assert_bool(bool(globals["was_interrupted"])).is_true()
	assert_bool(event_stmt.is_interrupted()).is_true()

	interpreter.cleanup()


func test_interrupting_delayed_command_in_dialog_stops_event_progress() -> void:
	# Interrupting an in-flight command inside a dialog option should abort the
	# surrounding event just as cleanly as interruption in a plain block. The
	# dialog must not resume and the post-dialog append must never run.
	var source := _load_fixture("delayed_command_interrupt_in_dialog.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("delayed_command_interrupt_in_dialog.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()
	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(1)

	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	resolver.resolve(statements)
	var dialog_player := DialogPlayerDouble.new([0])
	escoria.set("dialog_player", dialog_player)

	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	var event_stmt: ESCGrammarStmts.Event = statements[0]
	interpreter.call_deferred("interpret", statements)
	await escoria.get_tree().create_timer(0.05).timeout
	interpreter.interrupt()
	await event_stmt.finished

	var globals := interpreter.get_global_values()
	assert_bool(globals.has("result")).is_true()
	assert_str(String(globals["result"])).is_equal("start")
	assert_bool(globals.has("was_interrupted")).is_true()
	assert_bool(bool(globals["was_interrupted"])).is_true()
	assert_bool(event_stmt.is_interrupted()).is_true()

	_cleanup_dialog_test(interpreter, dialog_player)


func test_interrupting_delayed_command_stops_multi_iteration_loop() -> void:
	# Interrupting a delayed command in the first loop iteration should stop the
	# loop itself, not just the current statement. The counter must therefore
	# stay at zero and the post-loop append must never run.
	var source := _load_fixture("delayed_command_interrupt_in_multi_loop.esc")
	var compiler := ESCCompiler.new()
	var scanner := ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(_fixture_path("delayed_command_interrupt_in_multi_loop.esc"))

	var tokens: Array = scanner.scan_tokens()
	var parser := ESCParser.new()
	parser.init(compiler, tokens, "")

	var statements := parser.parse()
	assert_bool(compiler.had_error).is_false()
	assert_int(statements.size()).is_equal(1)

	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	resolver.resolve(statements)

	assert_object(statements[0]).is_instanceof(ESCGrammarStmts.Event)
	var event_stmt: ESCGrammarStmts.Event = statements[0]
	interpreter.call_deferred("interpret", statements)
	await escoria.get_tree().create_timer(0.05).timeout
	interpreter.interrupt()
	await event_stmt.finished

	var globals := interpreter.get_global_values()
	assert_bool(globals.has("result")).is_true()
	assert_str(String(globals["result"])).is_equal("start")
	assert_bool(globals.has("was_interrupted")).is_true()
	assert_bool(bool(globals["was_interrupted"])).is_true()
	assert_bool(globals.has("count")).is_true()
	assert_float(float(globals["count"])).is_equal(0.0)
	assert_bool(event_stmt.is_interrupted()).is_true()

	interpreter.cleanup()


func test_invalid_command_does_not_continue_event() -> void:
	# A missing command should fail the current event cleanly instead of letting
	# later statements continue as if the command had succeeded.
	var outcome := await _interpret_fixture("invalid_command_does_not_continue.esc")
	assert_bool(outcome.globals.has("result")).is_true()
	assert_str(String(outcome.globals["result"])).is_equal("start")


func test_invalid_command_in_dialog_does_not_continue_event() -> void:
	# A missing command inside a dialog option should still terminate the event
	# cleanly. The assignment after the dialog must not run.
	var outcome := await _interpret_fixture(
		"invalid_command_in_dialog_stops_event.esc",
		[0]
	)
	assert_bool(outcome.globals.has("result")).is_true()
	assert_str(String(outcome.globals["result"])).is_equal("start")


func test_invalid_command_in_loop_does_not_continue_event() -> void:
	# A missing command inside a loop body should escape the loop as a terminal
	# runtime error instead of allowing later loop or post-loop statements to run.
	var outcome := await _interpret_fixture("invalid_command_in_loop_stops_event.esc")
	assert_bool(outcome.globals.has("result")).is_true()
	assert_str(String(outcome.globals["result"])).is_equal("start")
	assert_bool(outcome.globals.has("count")).is_true()
	assert_float(float(outcome.globals["count"])).is_equal(0.0)


func test_dialog_option_scope_shadowing_restores_outer_local() -> void:
	# A dialog option body introduces nested block scope. Assignments inside the
	# option should see the inner shadowing variable, while execution after the
	# dialog must still resolve the original outer local.
	var outcome := await _interpret_fixture(
		"dialog_scope_shadowing.esc",
		[0]
	)
	assert_bool(outcome.globals.has("result")).is_true()
	assert_str(String(outcome.globals["result"])).is_equal("inner:outer")


func test_interrupting_background_channel_does_not_interrupt_front_channel() -> void:
	# Background-channel interruption should only affect commands running on
	# that channel. The front event must still complete normally while the
	# background event should finish as interrupted once its in-flight command
	# observes the interrupt.
	var events := _load_fixture_events("channel_interrupt_isolation.esc")
	assert_bool(events.has("front_event")).is_true()
	assert_bool(events.has("background_event")).is_true()
	escoria.globals_manager.set_global("channel_front_result", "start")
	escoria.globals_manager.set_global("channel_background_result", "start")
	escoria.globals_manager.set_global("channel_front_was_interrupted", false)
	escoria.globals_manager.set_global("channel_background_was_interrupted", false)

	var signal_results := {
		"front": null,
		"background": null,
	}
	var on_front_finished := func(return_code, event_name) -> void:
		if event_name == "front_event":
			signal_results["front"] = [return_code, event_name]
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if event_name == "background_event" and finished_channel_name == "bg_test":
			signal_results["background"] = [return_code, event_name, finished_channel_name]

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_event(events["front_event"])
	escoria.event_manager.queue_background_event("bg_test", events["background_event"])

	await escoria.get_tree().create_timer(0.05).timeout
	escoria.event_manager.interrupt_channel("bg_test")

	while signal_results["front"] == null or signal_results["background"] == null:
		await escoria.get_tree().process_frame

	var front_finished = signal_results["front"]
	var background_finished = signal_results["background"]

	assert_int(int(front_finished[0])).is_equal(ESCExecution.RC_OK)
	assert_int(int(background_finished[0])).is_equal(ESCExecution.RC_INTERRUPTED)
	assert_str(String(escoria.globals_manager.get_global("channel_front_result"))).is_equal("front-cmd-after")
	assert_bool(escoria.globals_manager.get_global("channel_front_was_interrupted") == true).is_false()
	assert_str(String(escoria.globals_manager.get_global("channel_background_result"))).is_equal("start")
	assert_bool(escoria.globals_manager.get_global("channel_background_was_interrupted") == true).is_true()

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_concurrent_channels_complete_without_interrupting_each_other() -> void:
	# Two events on different channels should be able to run at the same time
	# and still complete normally when no interrupt is issued.
	var events := _load_fixture_events("channel_interrupt_isolation.esc")
	assert_bool(events.has("front_event")).is_true()
	assert_bool(events.has("background_event")).is_true()
	escoria.globals_manager.set_global("channel_front_result", "start")
	escoria.globals_manager.set_global("channel_background_result", "start")
	escoria.globals_manager.set_global("channel_front_was_interrupted", false)
	escoria.globals_manager.set_global("channel_background_was_interrupted", false)

	var signal_results := {
		"front": null,
		"background": null,
	}
	var on_front_finished := func(return_code, event_name) -> void:
		if event_name == "front_event":
			signal_results["front"] = [return_code, event_name]
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if event_name == "background_event" and finished_channel_name == "bg_test":
			signal_results["background"] = [return_code, event_name, finished_channel_name]

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_event(events["front_event"])
	escoria.event_manager.queue_background_event("bg_test", events["background_event"])

	while signal_results["front"] == null or signal_results["background"] == null:
		await escoria.get_tree().process_frame

	var front_finished = signal_results["front"]
	var background_finished = signal_results["background"]

	assert_int(int(front_finished[0])).is_equal(ESCExecution.RC_OK)
	assert_int(int(background_finished[0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(escoria.globals_manager.get_global("channel_front_result"))).is_equal("front-cmd-after")
	assert_bool(escoria.globals_manager.get_global("channel_front_was_interrupted") == true).is_false()
	assert_str(String(escoria.globals_manager.get_global("channel_background_result"))).is_equal("bg-cmd-after")
	assert_bool(escoria.globals_manager.get_global("channel_background_was_interrupted") == true).is_false()

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_interrupting_channel_clears_queued_successor_events() -> void:
	# Interrupting a channel should stop the currently running event and purge
	# later queued events on that same channel before they ever start running.
	var events := _load_fixture_events("channel_interrupt_clears_queue.esc")
	assert_bool(events.has("first")).is_true()
	assert_bool(events.has("second")).is_true()
	escoria.globals_manager.set_global("bg_queue_interrupted", false)

	var background_finishes: Array = []
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			background_finishes.append([return_code, event_name, finished_channel_name])

	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_background_event("bg_test", events["first"])
	escoria.event_manager.queue_background_event("bg_test", events["second"])

	await escoria.get_tree().create_timer(0.05).timeout
	escoria.event_manager.interrupt_channel("bg_test")

	while background_finishes.is_empty():
		await escoria.get_tree().process_frame

	assert_int(background_finishes.size()).is_equal(1)
	assert_int(int(background_finishes[0][0])).is_equal(ESCExecution.RC_INTERRUPTED)
	assert_str(String(background_finishes[0][1])).is_equal("first")
	assert_str(String(background_finishes[0][2])).is_equal("bg_test")
	assert_str(String(escoria.globals_manager.get_global("bg_queue_result"))).is_equal("first")
	assert_bool(escoria.globals_manager.get_global("bg_queue_interrupted") == true).is_true()

	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_concurrent_channels_do_not_block_other_channel_queues() -> void:
	# Each channel should serialize only its own queue. A front-channel event
	# must complete independently while a background channel works through two
	# queued events in order.
	var events := _load_fixture_events("channel_queue_progress_isolated.esc")
	assert_bool(events.has("front_event")).is_true()
	assert_bool(events.has("background_first")).is_true()
	assert_bool(events.has("background_second")).is_true()
	escoria.globals_manager.set_global("isolated_front_result", "start")
	escoria.globals_manager.set_global("isolated_background_result", "start")
	escoria.globals_manager.set_global("isolated_front_interrupted", false)
	escoria.globals_manager.set_global("isolated_background_interrupted", false)

	var signal_results := {
		"front": null,
		"background_finishes": [],
	}
	var on_front_finished := func(return_code, event_name) -> void:
		if event_name == "front_event":
			signal_results["front"] = [return_code, event_name]
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			signal_results["background_finishes"].append([return_code, event_name, finished_channel_name])

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_event(events["front_event"])
	escoria.event_manager.queue_background_event("bg_test", events["background_first"])
	escoria.event_manager.queue_background_event("bg_test", events["background_second"])

	while signal_results["front"] == null or signal_results["background_finishes"].size() < 2:
		await escoria.get_tree().process_frame

	var front_finished = signal_results["front"]
	var background_finishes: Array = signal_results["background_finishes"]

	assert_int(int(front_finished[0])).is_equal(ESCExecution.RC_OK)
	assert_int(int(background_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(background_finishes[0][1])).is_equal("background_first")
	assert_int(int(background_finishes[1][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(background_finishes[1][1])).is_equal("background_second")
	assert_str(String(escoria.globals_manager.get_global("isolated_front_result"))).is_equal("front-cmd-after")
	assert_bool(escoria.globals_manager.get_global("isolated_front_interrupted") == true).is_false()
	assert_str(String(escoria.globals_manager.get_global("isolated_background_result"))).is_equal("first-cmd-after-first-second")
	assert_bool(escoria.globals_manager.get_global("isolated_background_interrupted") == true).is_false()

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_global_interrupt_stops_running_channels_and_clears_queues() -> void:
	# A global interrupt should stop every currently running channel and purge
	# any queued successor events before they start. This fixture queues one
	# running and one queued event on both `_front` and `bg_test`.
	var events := _load_fixture_events("global_interrupt_clears_all_channels.esc")
	assert_bool(events.has("front_running")).is_true()
	assert_bool(events.has("front_queued")).is_true()
	assert_bool(events.has("background_running")).is_true()
	assert_bool(events.has("background_queued")).is_true()
	escoria.globals_manager.set_global("global_interrupt_front_result", "start")
	escoria.globals_manager.set_global("global_interrupt_background_result", "start")
	escoria.globals_manager.set_global("global_interrupt_front_was_interrupted", false)
	escoria.globals_manager.set_global("global_interrupt_background_was_interrupted", false)

	var signal_results := {
		"front_finishes": [],
		"background_finishes": [],
	}
	var on_front_finished := func(return_code, event_name) -> void:
		signal_results["front_finishes"].append([return_code, event_name])
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			signal_results["background_finishes"].append([return_code, event_name, finished_channel_name])

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_event(events["front_running"])
	escoria.event_manager.queue_event(events["front_queued"])
	escoria.event_manager.queue_background_event("bg_test", events["background_running"])
	escoria.event_manager.queue_background_event("bg_test", events["background_queued"])

	await escoria.get_tree().create_timer(0.05).timeout
	escoria.event_manager.interrupt()

	while signal_results["front_finishes"].is_empty() or signal_results["background_finishes"].is_empty():
		await escoria.get_tree().process_frame

	await escoria.get_tree().create_timer(0.05).timeout

	assert_int(signal_results["front_finishes"].size()).is_equal(1)
	assert_int(int(signal_results["front_finishes"][0][0])).is_equal(ESCExecution.RC_INTERRUPTED)
	assert_str(String(signal_results["front_finishes"][0][1])).is_equal("front_running")
	assert_int(signal_results["background_finishes"].size()).is_equal(1)
	assert_int(int(signal_results["background_finishes"][0][0])).is_equal(ESCExecution.RC_INTERRUPTED)
	assert_str(String(signal_results["background_finishes"][0][1])).is_equal("background_running")
	assert_str(String(signal_results["background_finishes"][0][2])).is_equal("bg_test")
	assert_str(String(escoria.globals_manager.get_global("global_interrupt_front_result"))).is_equal("start")
	assert_bool(escoria.globals_manager.get_global("global_interrupt_front_was_interrupted") == true).is_true()
	assert_str(String(escoria.globals_manager.get_global("global_interrupt_background_result"))).is_equal("start")
	assert_bool(escoria.globals_manager.get_global("global_interrupt_background_was_interrupted") == true).is_true()

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_queue_event_block_waits_for_correct_background_event_under_concurrency() -> void:
	# Blocking queue_event waits must ignore unrelated background completions,
	# including earlier events on the same channel, and return only when the
	# specifically requested background event finishes.
	var script_object := _compile_fixture_script("queue_event_block_waits_for_correct_background_event.esc")
	assert_bool(script_object.events.has("background_first")).is_true()
	assert_bool(script_object.events.has("background_target")).is_true()
	assert_bool(script_object.events.has("front_event")).is_true()
	escoria.globals_manager.set_global("block_wait_result", "start")
	escoria.globals_manager.set_global("block_wait_front_result", "start")

	escoria.event_manager.queue_background_event("bg_test", script_object.events["background_first"])
	escoria.event_manager.queue_event(script_object.events["front_event"])

	var block_rc: int = await escoria.event_manager.queue_event_from_esc(
		script_object,
		"background_target",
		"bg_test",
		true
	)

	assert_int(block_rc).is_equal(ESCExecution.RC_OK)
	assert_str(String(escoria.globals_manager.get_global("block_wait_result"))).is_equal("first-target")
	assert_str(String(escoria.globals_manager.get_global("block_wait_front_result"))).is_equal("front")


func test_queue_event_block_waits_for_correct_front_event_under_concurrency() -> void:
	# Blocking front queue_event waits must ignore both background completions
	# and earlier foreground events, returning only when the specifically
	# requested front event finishes.
	var script_object := _compile_fixture_script("queue_event_block_waits_for_correct_front_event.esc")
	assert_bool(script_object.events.has("front_first")).is_true()
	assert_bool(script_object.events.has("front_target")).is_true()
	assert_bool(script_object.events.has("background_event")).is_true()
	escoria.globals_manager.set_global("front_block_wait_result", "start")
	escoria.globals_manager.set_global("front_block_wait_background_result", "start")

	escoria.event_manager.queue_event(script_object.events["front_first"])
	escoria.event_manager.queue_background_event("bg_test", script_object.events["background_event"])

	var block_rc: int = await escoria.event_manager.queue_event_from_esc(
		script_object,
		"front_target",
		"_front",
		true
	)

	assert_int(block_rc).is_equal(ESCExecution.RC_OK)
	assert_str(String(escoria.globals_manager.get_global("front_block_wait_result"))).is_equal("first-target")
	assert_str(String(escoria.globals_manager.get_global("front_block_wait_background_result"))).is_equal("background")


func test_sequential_front_events_preserve_globals_between_runtime_interpreters() -> void:
	# Each event-manager run currently observes globals written by earlier runs.
	# The ownership refactor must preserve that user-visible behavior even though
	# the underlying interpreter instances will stop sharing a singleton slot.
	var events := _load_fixture_events("interpreter_runtime_state_persists_between_events.esc")
	assert_bool(events.has("first")).is_true()
	assert_bool(events.has("second")).is_true()

	var front_finishes: Array = []
	var on_front_finished := func(return_code, event_name) -> void:
		front_finishes.append([return_code, event_name])

	escoria.event_manager.event_finished.connect(on_front_finished)

	escoria.event_manager.queue_event(events["first"])
	while front_finishes.size() < 1:
		await escoria.get_tree().process_frame

	escoria.event_manager.queue_event(events["second"])
	while front_finishes.size() < 2:
		await escoria.get_tree().process_frame

	assert_int(front_finishes.size()).is_equal(2)
	assert_int(int(front_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(front_finishes[0][1])).is_equal("first")
	assert_int(int(front_finishes[1][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(front_finishes[1][1])).is_equal("second")
	assert_str(String(escoria.globals_manager.get_global("interpreter_runtime_result"))).is_equal("first-second")

	escoria.event_manager.event_finished.disconnect(on_front_finished)


func test_background_event_sees_globals_written_by_previous_front_event() -> void:
	# Front and background channels each create their own runtime interpreter.
	# A background event queued after a front event must still observe globals
	# written by that earlier front-channel execution.
	var events := _load_fixture_events("interpreter_runtime_state_persists_between_events.esc")
	assert_bool(events.has("background_seed")).is_true()
	assert_bool(events.has("background_after")).is_true()

	var front_finishes: Array = []
	var background_finishes: Array = []
	var on_front_finished := func(return_code, event_name) -> void:
		front_finishes.append([return_code, event_name])
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			background_finishes.append([return_code, event_name, finished_channel_name])

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_event(events["background_seed"])
	while front_finishes.size() < 1:
		await escoria.get_tree().process_frame

	escoria.event_manager.queue_background_event("bg_test", events["background_after"])
	while background_finishes.size() < 1:
		await escoria.get_tree().process_frame

	assert_int(front_finishes.size()).is_equal(1)
	assert_int(int(front_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(front_finishes[0][1])).is_equal("background_seed")
	assert_int(background_finishes.size()).is_equal(1)
	assert_int(int(background_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(background_finishes[0][1])).is_equal("background_after")
	assert_str(String(background_finishes[0][2])).is_equal("bg_test")
	assert_str(String(escoria.globals_manager.get_global("interpreter_runtime_background_result"))).is_equal("first-background")

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_running_interpreter_sees_new_global_defined_by_other_channel() -> void:
	# A runtime interpreter that is already running must observe globals declared
	# by a concurrent channel after it has started. Otherwise overlapping events
	# can regress from shared-global behavior to "Undefined variable" failures.
	var events := _load_fixture_events("concurrent_new_global_visibility.esc")
	assert_bool(events.has("front_waits_for_new_global")).is_true()
	assert_bool(events.has("background_declares_new_global")).is_true()

	var front_finishes: Array = []
	var background_finishes: Array = []
	var on_front_finished := func(return_code, event_name) -> void:
		front_finishes.append([return_code, event_name])
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			background_finishes.append([return_code, event_name, finished_channel_name])

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_event(events["front_waits_for_new_global"])
	await escoria.get_tree().create_timer(0.05).timeout
	escoria.event_manager.queue_background_event("bg_test", events["background_declares_new_global"])

	while front_finishes.is_empty() or background_finishes.is_empty():
		await escoria.get_tree().process_frame

	assert_int(int(front_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(str(front_finishes[0][1])).is_equal("front_waits_for_new_global")
	assert_int(int(background_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(str(background_finishes[0][1])).is_equal("background_declares_new_global")
	assert_str(str(escoria.globals_manager.get_global("concurrent_visibility_result"))).is_equal("from-background")

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_queue_background_event_allows_consecutive_duplicate_queue_entries() -> void:
	# Queueing the same background event twice in a row should be allowed on a
	# background channel. In practice these queues are populated via ASHES
	# commands, so the second request should remain queued behind the first run.
	var events := _load_fixture_events("background_duplicate_suppression.esc")
	assert_bool(events.has("repeat_event")).is_true()
	escoria.globals_manager.set_global("background_duplicate_count", 0)
	escoria.globals_manager.set_global("background_duplicate_last", "start")

	var background_finishes: Array = []
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			background_finishes.append([return_code, event_name, finished_channel_name])

	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_background_event("bg_test", events["repeat_event"])
	escoria.event_manager.queue_background_event("bg_test", events["repeat_event"])

	while background_finishes.size() < 2:
		await escoria.get_tree().process_frame

	assert_int(background_finishes.size()).is_equal(2)
	assert_int(int(background_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(background_finishes[0][1])).is_equal("repeat_event")
	assert_str(String(background_finishes[0][2])).is_equal("bg_test")
	assert_int(int(background_finishes[1][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(background_finishes[1][1])).is_equal("repeat_event")
	assert_str(String(background_finishes[1][2])).is_equal("bg_test")
	assert_int(int(escoria.globals_manager.get_global("background_duplicate_count"))).is_equal(2)
	assert_str(String(escoria.globals_manager.get_global("background_duplicate_last"))).is_equal("tick")

	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_queue_background_event_allows_same_event_after_current_run_starts() -> void:
	# Once the first background event is already running, queueing the same event
	# again on that channel should queue a second run behind it instead of being
	# suppressed as a duplicate.
	var events := _load_fixture_events("background_duplicate_suppression.esc")
	assert_bool(events.has("repeat_event")).is_true()
	escoria.globals_manager.set_global("background_duplicate_count", 0)
	escoria.globals_manager.set_global("background_duplicate_last", "start")

	var background_finishes: Array = []
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			background_finishes.append([return_code, event_name, finished_channel_name])

	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_background_event("bg_test", events["repeat_event"])
	await escoria.get_tree().create_timer(0.01).timeout
	escoria.event_manager.queue_background_event("bg_test", events["repeat_event"])

	while background_finishes.size() < 2:
		await escoria.get_tree().process_frame

	assert_int(background_finishes.size()).is_equal(2)
	assert_int(int(background_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(background_finishes[0][1])).is_equal("repeat_event")
	assert_int(int(background_finishes[1][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(background_finishes[1][1])).is_equal("repeat_event")
	assert_int(int(escoria.globals_manager.get_global("background_duplicate_count"))).is_equal(2)
	assert_str(String(escoria.globals_manager.get_global("background_duplicate_last"))).is_equal("tick")

	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_global_interrupt_preserves_exception_events() -> void:
	# `interrupt(exceptions=...)` should leave only the named running and queued
	# events alive. Here the front running event and one queued background event
	# are excepted, while the other front/background events must be cleared.
	var events := _load_fixture_events("global_interrupt_preserves_exceptions.esc")
	assert_bool(events.has("front_keep")).is_true()
	assert_bool(events.has("front_drop")).is_true()
	assert_bool(events.has("background_drop")).is_true()
	assert_bool(events.has("background_keep")).is_true()
	escoria.globals_manager.set_global("interrupt_except_front_result", "start")
	escoria.globals_manager.set_global("interrupt_except_front_interrupted", false)
	escoria.globals_manager.set_global("interrupt_except_background_result", "start")
	escoria.globals_manager.set_global("interrupt_except_background_interrupted", false)
	escoria.globals_manager.set_global("interrupt_except_background_keep_result", "start")

	var signal_results := {
		"front_finishes": [],
		"background_finishes": [],
	}
	var on_front_finished := func(return_code, event_name) -> void:
		signal_results["front_finishes"].append([return_code, event_name])
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			signal_results["background_finishes"].append([return_code, event_name, finished_channel_name])

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_event(events["front_keep"])
	escoria.event_manager.queue_event(events["front_drop"])
	escoria.event_manager.queue_background_event("bg_test", events["background_drop"])
	escoria.event_manager.queue_background_event("bg_test", events["background_keep"])

	await escoria.get_tree().create_timer(0.05).timeout
	escoria.event_manager.interrupt(PackedStringArray(["front_keep", "background_keep"]))

	while signal_results["front_finishes"].is_empty() or signal_results["background_finishes"].size() < 2:
		await escoria.get_tree().process_frame

	assert_int(signal_results["front_finishes"].size()).is_equal(1)
	assert_int(int(signal_results["front_finishes"][0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(signal_results["front_finishes"][0][1])).is_equal("front_keep")
	assert_int(signal_results["background_finishes"].size()).is_equal(2)
	assert_int(int(signal_results["background_finishes"][0][0])).is_equal(ESCExecution.RC_INTERRUPTED)
	assert_str(String(signal_results["background_finishes"][0][1])).is_equal("background_drop")
	assert_int(int(signal_results["background_finishes"][1][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(signal_results["background_finishes"][1][1])).is_equal("background_keep")
	assert_str(String(escoria.globals_manager.get_global("interrupt_except_front_result"))).is_equal("front-cmd-after")
	assert_bool(escoria.globals_manager.get_global("interrupt_except_front_interrupted") == true).is_false()
	assert_str(String(escoria.globals_manager.get_global("interrupt_except_background_result"))).is_equal("start")
	assert_bool(escoria.globals_manager.get_global("interrupt_except_background_interrupted") == true).is_true()
	assert_str(String(escoria.globals_manager.get_global("interrupt_except_background_keep_result"))).is_equal("bg-keep-after")

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_scheduled_front_event_runs_after_current_front_event_while_background_is_busy() -> void:
	# Scheduled events always feed the `_front` queue. They should still dispatch
	# while a background channel is busy, but must wait for the current front
	# event to finish before the scheduled front event runs.
	var events := _load_fixture_events("scheduled_front_event_with_busy_background.esc")
	assert_bool(events.has("front_running")).is_true()
	assert_bool(events.has("scheduled_front")).is_true()
	assert_bool(events.has("background_running")).is_true()
	escoria.globals_manager.set_global("scheduled_front_result", "start")
	escoria.globals_manager.set_global("scheduled_front_interrupted", false)
	escoria.globals_manager.set_global("scheduled_background_result", "start")
	escoria.globals_manager.set_global("scheduled_background_interrupted", false)

	var signal_results := {
		"front_finishes": [],
		"background_finishes": [],
	}
	var on_front_finished := func(return_code, event_name) -> void:
		signal_results["front_finishes"].append([return_code, event_name])
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			signal_results["background_finishes"].append([return_code, event_name, finished_channel_name])

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_event(events["front_running"])
	escoria.event_manager.queue_background_event("bg_test", events["background_running"])
	escoria.event_manager.schedule_event(events["scheduled_front"], 0.05, "")

	while signal_results["front_finishes"].size() < 2 or signal_results["background_finishes"].is_empty():
		await escoria.get_tree().process_frame

	assert_int(signal_results["front_finishes"].size()).is_equal(2)
	assert_int(int(signal_results["front_finishes"][0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(signal_results["front_finishes"][0][1])).is_equal("front_running")
	assert_int(int(signal_results["front_finishes"][1][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(signal_results["front_finishes"][1][1])).is_equal("scheduled_front")
	assert_int(signal_results["background_finishes"].size()).is_equal(1)
	assert_int(int(signal_results["background_finishes"][0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(signal_results["background_finishes"][0][1])).is_equal("background_running")
	assert_str(String(escoria.globals_manager.get_global("scheduled_front_result"))).is_equal("front-running-after-scheduled")
	assert_bool(escoria.globals_manager.get_global("scheduled_front_interrupted") == true).is_false()
	assert_str(String(escoria.globals_manager.get_global("scheduled_background_result"))).is_equal("background-running-after")
	assert_bool(escoria.globals_manager.get_global("scheduled_background_interrupted") == true).is_false()

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


func test_global_interrupt_preserves_scheduled_events_before_dispatch() -> void:
	# Global interrupt should stop the currently running event, but it should
	# not clear scheduled events that have not yet been promoted into the front
	# queue. The scheduled front event should therefore still dispatch and
	# complete normally after the interrupted event finishes.
	var events := _load_fixture_events("scheduled_event_interrupted_before_dispatch.esc")
	assert_bool(events.has("front_running")).is_true()
	assert_bool(events.has("scheduled_front")).is_true()
	escoria.globals_manager.set_global("scheduled_interrupt_result", "start")
	escoria.globals_manager.set_global("scheduled_interrupt_was_interrupted", false)

	var front_finishes: Array = []
	var on_front_finished := func(return_code, event_name) -> void:
		front_finishes.append([return_code, event_name])

	escoria.event_manager.event_finished.connect(on_front_finished)

	escoria.event_manager.queue_event(events["front_running"])
	escoria.event_manager.schedule_event(events["scheduled_front"], 0.2, "")

	await escoria.get_tree().create_timer(0.05).timeout
	escoria.event_manager.interrupt()

	while front_finishes.is_empty():
		await escoria.get_tree().process_frame

	await escoria.get_tree().create_timer(0.25).timeout

	assert_int(front_finishes.size()).is_equal(2)
	assert_int(int(front_finishes[0][0])).is_equal(ESCExecution.RC_INTERRUPTED)
	assert_str(String(front_finishes[0][1])).is_equal("front_running")
	assert_int(int(front_finishes[1][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(front_finishes[1][1])).is_equal("scheduled_front")
	assert_str(String(escoria.globals_manager.get_global("scheduled_interrupt_result"))).is_equal("start-scheduled")
	assert_bool(escoria.globals_manager.get_global("scheduled_interrupt_was_interrupted") == true).is_true()

	escoria.event_manager.event_finished.disconnect(on_front_finished)


func test_clear_event_queue_preserves_scheduled_events() -> void:
	# Clearing the event queue should only remove events that are already queued
	# for execution. Scheduled events live in a separate list until `_process()`
	# promotes them into the front queue, so they should still dispatch after
	# `clear_event_queue()` is called.
	var events := _load_fixture_events("scheduled_event_interrupted_before_dispatch.esc")
	assert_bool(events.has("scheduled_front")).is_true()
	escoria.globals_manager.set_global("scheduled_interrupt_result", "start")

	var front_finishes: Array = []
	var on_front_finished := func(return_code, event_name) -> void:
		front_finishes.append([return_code, event_name])

	escoria.event_manager.event_finished.connect(on_front_finished)

	escoria.event_manager.schedule_event(events["scheduled_front"], 0.05, "")
	escoria.event_manager.clear_event_queue()

	while front_finishes.is_empty():
		await escoria.get_tree().process_frame

	assert_int(front_finishes.size()).is_equal(1)
	assert_int(int(front_finishes[0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(front_finishes[0][1])).is_equal("scheduled_front")
	assert_str(String(escoria.globals_manager.get_global("scheduled_interrupt_result"))).is_equal("start-scheduled")

	escoria.event_manager.event_finished.disconnect(on_front_finished)


func test_interrupt_channel_does_not_affect_still_scheduled_front_events() -> void:
	# A scheduled front event should be unaffected by `interrupt_channel()` for a
	# background channel while it is still waiting in `scheduled_events`. Once it
	# is later promoted into `_front`, it should run like any other front-queue
	# event.
	var events := _load_fixture_events("scheduled_front_event_with_busy_background.esc")
	assert_bool(events.has("scheduled_front")).is_true()
	assert_bool(events.has("background_running")).is_true()
	escoria.globals_manager.set_global("scheduled_front_result", "start")
	escoria.globals_manager.set_global("scheduled_front_interrupted", false)
	escoria.globals_manager.set_global("scheduled_background_result", "start")
	escoria.globals_manager.set_global("scheduled_background_interrupted", false)

	var signal_results := {
		"front_finishes": [],
		"background_finishes": [],
	}
	var on_front_finished := func(return_code, event_name) -> void:
		signal_results["front_finishes"].append([return_code, event_name])
	var on_background_finished := func(return_code, event_name, finished_channel_name) -> void:
		if finished_channel_name == "bg_test":
			signal_results["background_finishes"].append([return_code, event_name, finished_channel_name])

	escoria.event_manager.event_finished.connect(on_front_finished)
	escoria.event_manager.background_event_finished.connect(on_background_finished)

	escoria.event_manager.queue_background_event("bg_test", events["background_running"])
	escoria.event_manager.schedule_event(events["scheduled_front"], 0.2, "")

	await escoria.get_tree().create_timer(0.05).timeout
	escoria.event_manager.interrupt_channel("bg_test")

	while signal_results["front_finishes"].is_empty() or signal_results["background_finishes"].is_empty():
		await escoria.get_tree().process_frame

	assert_int(signal_results["background_finishes"].size()).is_equal(1)
	assert_int(int(signal_results["background_finishes"][0][0])).is_equal(ESCExecution.RC_INTERRUPTED)
	assert_str(String(signal_results["background_finishes"][0][1])).is_equal("background_running")
	assert_int(signal_results["front_finishes"].size()).is_equal(1)
	assert_int(int(signal_results["front_finishes"][0][0])).is_equal(ESCExecution.RC_OK)
	assert_str(String(signal_results["front_finishes"][0][1])).is_equal("scheduled_front")
	assert_str(String(escoria.globals_manager.get_global("scheduled_front_result"))).is_equal("start-scheduled")
	assert_bool(escoria.globals_manager.get_global("scheduled_front_interrupted") == true).is_false()
	assert_str(String(escoria.globals_manager.get_global("scheduled_background_result"))).is_equal("start")
	assert_bool(escoria.globals_manager.get_global("scheduled_background_interrupted") == true).is_true()

	escoria.event_manager.event_finished.disconnect(on_front_finished)
	escoria.event_manager.background_event_finished.disconnect(on_background_finished)


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


func test_set_animations_updates_persisted_player_resource_on_repeat_calls() -> void:
	# Room changes restore player animations from the reserved
	# `ANIMATION_RESOURCES` global. Repeated `set_animations()` calls must update
	# the stored path each time, otherwise the next room load re-applies a stale
	# costume even if the live player was changed back already.
	var previous_animations = escoria.globals_manager.get_global(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES
	)
	var room := ESCRoom.new()
	room.global_id = "test_room_issue_1226"
	escoria.object_manager.set_current_room(room)

	var player := load("res://game/characters/mark/mark.tscn").instantiate() as ESCPlayer
	player.global_id = "player"
	escoria.object_manager.register_object(
		ESCObject.new(player.global_id, player),
		room,
		true,
		false
	)
	escoria.globals_manager.set_global(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES,
		{},
		true
	)

	var command := SetAnimationsCommand.new()
	var jester_animations := "res://game/characters/mark/mark_animations_jester.tres"
	var default_animations := "res://game/characters/mark/mark_animations.tres"

	assert_int(command.run([player.global_id, jester_animations])).is_equal(ESCExecution.RC_OK)
	assert_int(command.run([player.global_id, default_animations])).is_equal(ESCExecution.RC_OK)

	var animations: Dictionary = escoria.globals_manager.get_global(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES
	)
	assert_bool(animations.has(player.global_id)).is_true()
	assert_str(String(animations[player.global_id])).is_equal(default_animations)

	var room_key := ESCRoomObjectsKey.new()
	room_key.room_global_id = room.global_id
	room_key.room_instance_id = room.get_instance_id()
	escoria.object_manager.unregister_object_by_global_id(player.global_id, room_key)
	escoria.globals_manager.set_global(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES,
		previous_animations if previous_animations != null else {},
		true
	)
	player.free()
	room.free()


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

	_cleanup_dialog_test(interpreter, dialog_player)

	return {
		"globals": globals,
		"dialog_choices_consumed": dialog_choices_consumed,
		"remaining_dialog_choices": remaining_dialog_choices,
	}


func test_dialog_start_args_are_passed_to_runtime_dialog() -> void:
	var script_object := _compile_fixture_script("dialog_start_args_reach_runtime.esc")
	var dialog_player := DialogPlayerDouble.new([1])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)
	assert_int(dialog_player.get_choices_consumed()).is_equal(1)

	var started_dialogs := dialog_player.get_dialogs_started()
	assert_int(started_dialogs.size()).is_equal(1)
	assert_str(started_dialogs[0]["avatar"]).is_equal("res://game/dialog_avatars/player.tres")
	assert_int(started_dialogs[0]["timeout"]).is_equal(5)
	assert_int(started_dialogs[0]["timeout_option"]).is_equal(2)
	assert_int(started_dialogs[0]["options_size"]).is_equal(2)

	_cleanup_dialog_test(interpreter, dialog_player)


func test_dialog_start_invalid_avatar_type_returns_error() -> void:
	var script_object := _compile_fixture_script("dialog_start_invalid_avatar_type.esc")
	var dialog_player := DialogPlayerDouble.new([])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)
	assert_int(dialog_player.get_choices_consumed()).is_equal(0)
	assert_int(dialog_player.get_dialogs_started().size()).is_equal(0)

	_cleanup_dialog_test(interpreter, dialog_player)


func test_dialog_start_invalid_timeout_type_returns_error() -> void:
	var script_object := _compile_fixture_script("dialog_start_invalid_timeout_type.esc")
	var dialog_player := DialogPlayerDouble.new([])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)
	assert_int(dialog_player.get_choices_consumed()).is_equal(0)
	assert_int(dialog_player.get_dialogs_started().size()).is_equal(0)

	_cleanup_dialog_test(interpreter, dialog_player)


func test_dialog_option_translation_key_is_passed_to_runtime_dialog() -> void:
	var script_object := _compile_fixture_script("dialog_option_translation_key.esc")
	var dialog_player := DialogPlayerDouble.new([0])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)
	assert_int(dialog_player.get_choices_consumed()).is_equal(1)

	var started_dialogs := dialog_player.get_dialogs_started()
	assert_int(started_dialogs.size()).is_equal(1)
	assert_array(started_dialogs[0]["option_keys"]).contains_exactly(["UNCLE_SVEN", ""])

	_cleanup_dialog_test(interpreter, dialog_player)


func test_dialog_start_invalid_timeout_option_type_returns_error() -> void:
	var script_object := _compile_fixture_script("dialog_start_invalid_timeout_option_type.esc")
	var dialog_player := DialogPlayerDouble.new([])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)
	assert_int(dialog_player.get_choices_consumed()).is_equal(0)
	assert_int(dialog_player.get_dialogs_started().size()).is_equal(0)

	_cleanup_dialog_test(interpreter, dialog_player)


func test_dialog_start_invalid_timeout_option_negative_returns_error() -> void:
	var script_object := _compile_fixture_script("dialog_start_invalid_timeout_option_negative.esc")
	var dialog_player := DialogPlayerDouble.new([])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)
	assert_int(dialog_player.get_choices_consumed()).is_equal(0)
	assert_int(dialog_player.get_dialogs_started().size()).is_equal(0)

	_cleanup_dialog_test(interpreter, dialog_player)


func test_dialog_option_translation_key_beats_legacy_prefix_fallback() -> void:
	var script_object := _compile_fixture_script("dialog_option_translation_key_beats_legacy_prefix.esc")
	var dialog_player := DialogPlayerDouble.new([0])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)

	var started_dialogs := dialog_player.get_dialogs_started()
	assert_int(started_dialogs.size()).is_equal(1)
	assert_array(started_dialogs[0]["option_keys"]).contains_exactly(["OUTER_KEY"])
	assert_array(started_dialogs[0]["option_texts"]).contains_exactly(["INNER_KEY:Fallback text"])

	_cleanup_dialog_test(interpreter, dialog_player)


func test_dialog_option_translation_key_with_condition_survives_runtime_filtering() -> void:
	var script_object := _compile_fixture_script("dialog_option_translation_key_with_condition.esc")
	var dialog_player := DialogPlayerDouble.new([0])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)

	var started_dialogs := dialog_player.get_dialogs_started()
	assert_int(started_dialogs.size()).is_equal(1)
	assert_int(started_dialogs[0]["options_size"]).is_equal(1)
	assert_array(started_dialogs[0]["option_keys"]).contains_exactly(["CONDITIONAL_KEY"])
	assert_array(started_dialogs[0]["option_texts"]).contains_exactly(["Conditional option"])

	_cleanup_dialog_test(interpreter, dialog_player)


func test_dialog_option_translation_key_with_expression_preserves_key_and_value() -> void:
	var script_object := _compile_fixture_script("dialog_option_translation_key_with_expression.esc")
	var dialog_player := DialogPlayerDouble.new([0])
	escoria.set("dialog_player", dialog_player)
	var interpreter := ESCInterpreter.new(ESCCompiler.load_commands(), {})
	var resolver := ESCResolver.new(interpreter)
	var event: ESCGrammarStmts.Event = script_object.events["talk"]

	assert_object(event).is_not_null()

	resolver.resolve(event)

	await interpreter.interpret(event)

	var started_dialogs := dialog_player.get_dialogs_started()
	assert_int(started_dialogs.size()).is_equal(1)
	assert_array(started_dialogs[0]["option_keys"]).contains_exactly(["DYNAMIC_KEY"])
	assert_array(started_dialogs[0]["option_texts"]).contains_exactly(["Dynamic option"])

	_cleanup_dialog_test(interpreter, dialog_player)


func _cleanup_dialog_test(interpreter: ESCInterpreter, dialog_player: DialogPlayerDouble) -> void:
	interpreter.cleanup()

	if dialog_player:
		escoria.set("dialog_player", null)
		dialog_player.queue_free()


func _load_fixture(name: String) -> String:
	return FileAccess.get_file_as_string(_fixture_path(name))


func _load_fixture_events(name: String) -> Dictionary:
	var script_object := _compile_fixture_script(name)
	return script_object.events


func _compile_fixture_script(name: String) -> ESCScript:
	var source := _load_fixture(name)
	var compiler := ESCCompiler.new()
	var script_object := compiler.compile(source, _fixture_path(name))
	assert_bool(compiler.had_error).is_false()
	return script_object


func _fixture_path(name: String) -> String:
	return "res://addons/escoria-core/testing/ashes/interpreter/fixtures/%s" % name
