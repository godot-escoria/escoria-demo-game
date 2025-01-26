class ESCLoggerBase:
	# Perform emergency savegame
	signal perform_emergency_savegame

	# Sends the error or warning message in the signal
	signal error_message_signal(message)

	# Log file format
	const LOG_FILE_FORMAT: String = "log_%s_%s.log"

	# Configured log level
	var _log_level: int

	# If true, assert() functions will not be called, thus the program won't exit or error.
	# Resets to false after an assert() call was ignored once.
	var dont_assert: bool = false


	# Constructor
	func _init():
		_log_level = ESCLogLevel.determine_escoria_log_level()


	func formatted_message(context: String, msg: String, letter: String) -> String:
		return "ESC ({0}) {1} {2}: {3}".format([_formatted_date(), letter, context, msg])

	# Trace log
	func trace(owner: Object, msg: String):
		var context: String = owner.get_script().resource_path.get_file()
		trace_message(context, msg)

	# Direct message trace log (requiring a string for the context)
	func trace_message(context: String, msg: String):
		print(formatted_message(context, msg, "T"))


	# Debug log
	func debug(owner: Object, msg: String):
		var context: String = owner.get_script().resource_path.get_file()
		debug_message(context, msg)

	# Static debug log (requiring a string for the context)
	func debug_message(context: String, msg: String):
		print(formatted_message(context, msg, "D"))


	func info(owner: Object, msg: String):
		var context: String = owner.get_script().resource_path.get_file()
		info_message(context, msg)

	# Static info log (requiring a string for the context)
	func info_message(context: String, msg: String):
		print(formatted_message(context, msg, "I"))


	# Warning log
	func warn(owner: Object, msg: String):
		var context: String = owner.get_script().resource_path.get_file()
		warn_message(context, msg)

	# Static warning log (requiring a string for the context)
	func warn_message(context: String, msg: String):
		print(formatted_message(context, msg, "W"))
		push_warning(formatted_message(context, msg, "W"))
		if ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.TERMINATE_ON_WARNINGS
		):
			if not dont_assert:
				assert(false)
				escoria.get_tree().quit()
			dont_assert = false
			error_message_signal.emit(msg)


	# Error log
	func error(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		error_message(context, msg)

	# Static error log (requiring a string for the context)
	func error_message(context: String, msg: String):
		printerr(formatted_message(context, msg, "E"))
		push_error(formatted_message(context, msg, "E"))
		if ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.TERMINATE_ON_ERRORS
		):
			if not dont_assert:
				assert(false)
				escoria.get_tree().quit()
			dont_assert = false
			error_message_signal.emit(msg)

	func get_log_level() -> int:
		return _log_level


	func _formatted_date():
		var info = Time.get_datetime_dict_from_system()
		info["year"] = "%04d" % info["year"]
		info["month"] = "%02d" % info["month"]
		info["day"] = "%02d" % info["day"]
		info["hour"] = "%02d" % info["hour"]
		info["minute"] = "%02d" % info["minute"]
		info["second"] = "%02d" % info["second"]
		return "{year}-{month}-{day}T{hour}:{minute}:{second}".format(info)


# A logger that logs to the terminal and to a log file.
class ESCLoggerFile extends ESCLoggerBase:
	# Log file handler
	var log_file: FileAccess

	# Constructor
	func _init():
		super()
		# This is left alone as this constructor is called from escoria.gd's own
		# constructor
		var log_file_path = ProjectSettings.get_setting(
			ESCProjectSettingsManager.LOG_FILE_PATH
		)
		var date = Time.get_datetime_dict_from_system()
		log_file_path = log_file_path.path_join(LOG_FILE_FORMAT % [
				str(date["year"]) + str(date["month"]) + str(date["day"]),
				str(date["hour"]) + str(date["minute"]) + str(date["second"])
			])
		log_file = FileAccess.open(
			log_file_path,
			FileAccess.WRITE
		)

	# Trace log
	func trace(owner: Object, msg: String):
		if _log_level >= ESCLogLevel.LOG_TRACE:
			_log_to_file(owner, msg, "T")
			super.trace(owner, msg)

	# Static trace log
	func trace_message(context: String, msg: String):
		if _log_level >= ESCLogLevel.LOG_TRACE:
			_log_to_file_message(context, msg, "T")
			super.trace_message(context, msg)

	# Debug log
	func debug(owner: Object, msg: String):
		if _log_level >= ESCLogLevel.LOG_DEBUG:
			_log_to_file(owner, msg, "D")
			super.debug(owner, msg)

	# Static debug log
	func debug_message(context: String, msg: String):
		if _log_level >= ESCLogLevel.LOG_DEBUG:
			_log_to_file_message(context, msg, "D")
			super.debug_message(context, msg)

	# Info log
	func info(owner: Object, msg: String):
		if _log_level >= ESCLogLevel.LOG_INFO:
			_log_to_file(owner, msg, "I")
			super.info(owner, msg)

	# Static info log
	func info_message(context: String, msg: String):
		if _log_level >= ESCLogLevel.LOG_INFO:
			_log_to_file_message(context, msg, "I")
			super.info_message(context, msg)

	# Warning log
	func warn(owner: Object, msg: String):
		if _log_level >= ESCLogLevel.LOG_WARNING:
			_log_to_file(owner, msg, "W")
			if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.TERMINATE_ON_WARNINGS
			):
				_log_stack_trace_to_file()
				print_stack()
				close_logs()
			super.warn(owner, msg)

	# Static warning log
	func warn_message(context: String, msg: String):
		if _log_level >= ESCLogLevel.LOG_WARNING:
			_log_to_file_message(context, msg, "W")
			if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.TERMINATE_ON_WARNINGS
			):
				_log_stack_trace_to_file()
				print_stack()
				close_logs()
			super.warn_message(context, msg)

	# Error log
	func error(owner: Object, msg: String):
		if _log_level >= ESCLogLevel.LOG_ERROR:
			_log_to_file(owner, msg, "E")
			if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.TERMINATE_ON_ERRORS
			):
				_log_stack_trace_to_file()
				print_stack()
				close_logs()
			super.error(owner, msg)

	# Static eror log
	func error_message(context: String, msg: String):
		if _log_level >= ESCLogLevel.LOG_ERROR:
			_log_to_file_message(context, msg, "E")
			if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.TERMINATE_ON_ERRORS
			):
				_log_stack_trace_to_file()
				print_stack()
				close_logs()
			super.error_message(context, msg)

	# Close the log file cleanly
	func close_logs():
		print("Closing logs peacefully.")
		_log_line_to_file("Closing logs peacefully.")
		log_file.close()


	func _log_to_file(owner: Object, msg: String, letter: String):
		var context: String
		if owner != null:
			context = owner.get_script().resource_path.get_file()
			_log_to_file_message(context, msg, letter)

	func _log_to_file_message(context: String, msg: String, letter: String):
		if log_file.is_open():
			log_file.store_string(formatted_message(context, msg, letter) + "\n")

	func _log_line_to_file(msg: String):
		if log_file.is_open():
			log_file.store_string(msg + "\n")

	func _log_stack_trace_to_file():
		var frame_number = 0
		for stack in get_stack().slice(2, get_stack().size()):
			_log_line_to_file(
				"Frame %s - %s:%s in function '%s'" % [
					str(frame_number),
					stack["source"],
					stack["line"],
					stack["function"],
				]
			)
			frame_number += 1


# A simple logger that logs to terminal using debug() function
class ESCLoggerVerbose extends ESCLoggerBase:
	func _init():
		pass

	func debug(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print(context, ": ", msg)
