class ESCLoggerBase:
	# Perform emergency savegame
	signal perform_emergency_savegame

	# Valid log levels
	enum { LOG_ERROR, LOG_WARNING, LOG_INFO, LOG_DEBUG, LOG_TRACE }

	# Log file format
	const LOG_FILE_FORMAT: String = "log_%s_%s.log"

	# A map of log level names to log level ints
	var _level_map: Dictionary = {
		"ERROR": LOG_ERROR,
		"WARNING": LOG_WARNING,
		"INFO": LOG_INFO,
		"DEBUG": LOG_DEBUG,
		"TRACE": LOG_TRACE,
	}

	# Configured log level
	var _log_level: int


	# Constructor
	func _init():
		_log_level = _level_map[ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.LOG_LEVEL
		).to_upper()]


	func formatted_message(context: String, msg: String, letter: String) -> String:
		return "ESC ({0}) {1} {2}: {3}".format([_formatted_date(), letter, context, msg])


	func trace(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print(formatted_message(context, msg, "T"))


	# Debug log
	func debug(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print(formatted_message(context, msg, "D"))


	func info(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print(formatted_message(context, msg, "I"))


	# Warning log
	func warn(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print(formatted_message(context, msg, "W"))
		push_warning(formatted_message(context, msg, "W"))
		if ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.TERMINATE_ON_WARNINGS
		):
			assert(false)
			escoria.get_tree().quit()


	# Error log
	func error(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		printerr(formatted_message(context, msg, "E"))
		push_error(formatted_message(context, msg, "E"))
		if ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.TERMINATE_ON_ERRORS
		):
			assert(false)
			escoria.get_tree().quit()


	func get_log_level() -> int:
		return _log_level

	func _formatted_date():
		var info = OS.get_datetime()
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
	var log_file: File

	# Constructor
	func _init():
		# Open logfile in write mode
		log_file = File.new()

		# This is left alone as this constructor is called from escoria.gd's own
		# constructor
		var log_file_path = ProjectSettings.get_setting(
			ESCProjectSettingsManager.LOG_FILE_PATH
		)
		var date = OS.get_datetime()
		log_file_path = log_file_path.plus_file(LOG_FILE_FORMAT % [
				str(date["year"]) + str(date["month"]) + str(date["day"]),
				str(date["hour"]) + str(date["minute"]) + str(date["second"])
			])
		log_file.open(
			log_file_path,
			File.WRITE
		)

	func trace(owner: Object, msg: String):
		if _log_level >= LOG_TRACE:
			_log_to_file(owner, msg, "T")
			.trace(owner, msg)

	# Debug log
	func debug(owner: Object, msg: String):
		if _log_level >= LOG_DEBUG:
			_log_to_file(owner, msg, "D")
			.debug(owner, msg)

	func info(owner: Object, msg: String):
		if _log_level >= LOG_INFO:
			_log_to_file(owner, msg, "I")
			.info(owner, msg)

	# Warning log
	func warn(owner: Object, msg: String):
		if _log_level >= LOG_WARNING:
			_log_to_file(owner, msg, "W")
			if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.TERMINATE_ON_WARNINGS
			):
				_log_stack_trace_to_file(owner)
				print_stack()
				close_logs()
			.warn(owner, msg)

	# Error log
	func error(owner: Object, msg: String):
		if _log_level >= LOG_ERROR:
			_log_to_file(owner, msg, "E")
			if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.TERMINATE_ON_ERRORS
			):
				_log_stack_trace_to_file(owner)
				print_stack()
				close_logs()
			.error(owner, msg)


	# Close the log file cleanly
	func close_logs():
		print("Closing logs peacefully.")
		_log_line_to_file("Closing logs peacefully.")
		log_file.close()


	func _log_to_file(owner: Object, msg: String, letter: String):
		if log_file.is_open():
			var context = ""
			if owner != null:
				context = owner.get_script().resource_path.get_file()
			log_file.store_string(formatted_message(context, msg, letter) + "\n")

	func _log_line_to_file(msg: String):
		if log_file.is_open():
			log_file.store_string(msg + "\n")

	func _log_stack_trace_to_file(owner: Object):
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

