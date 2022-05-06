class ESCLoggerBase:
	# Perform emergency savegame 
	signal perform_emergency_savegame
	
	# Log file format
	const  LOG_FILE_FORMAT: String = "log_%s_%s.log"
	
	# Valid log levels
	enum { LOG_ERROR, LOG_WARNING, LOG_INFO, LOG_DEBUG, LOG_TRACE }

	# A map of log level names to log level ints
	var _level_map: Dictionary = {
		"ERROR": LOG_ERROR,
		"WARNING": LOG_WARNING,
		"INFO": LOG_INFO,
		"DEBUG": LOG_DEBUG,
		"TRACE": LOG_TRACE,
	}
	
	# Constructor
	func _init():
		pass
	
	func trace(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print("ESC (T) {0} {1}: {2}".format([context, _formatted_date(), msg]))
	
	# Debug log
	func debug(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print("ESC (D) {0} {1}: {2}".format([context, _formatted_date(), msg]))
		
	func info(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print("ESC (I) {0} {1}: {2}".format([context, _formatted_date(), msg]))


# The path of the ESC file that was reported last (used for removing
# duplicate warnings
var warning_path: String

# Log file handler
var log_file: File

# Crash save filename
var crash_savegame_filename

# Did we crash already?
onready var crashed = false

# Valid log levels
enum { LOG_ERROR, LOG_WARNING, LOG_INFO, LOG_DEBUG, LOG_TRACE }


# A map of log level names to log level ints
var _level_map: Dictionary = {
	"ERROR": LOG_ERROR,
	"WARNING": LOG_WARNING,
	"INFO": LOG_INFO,
	"DEBUG": LOG_DEBUG,
	"TRACE": LOG_TRACE,
}


# Logger constructor
func _init():
	# Open logfile in write mode
	log_file = File.new()

	# this is left alone as this constructor is called from escoria.gd's own
	# constructor
	var log_file_path = ProjectSettings.get_setting(
		"escoria/debug/log_file_path"
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


# Log a trace message
#
# Global variables can be substituted into the text by wrapping the global
# name in braces.
# e.g. trace "There are {coin_count} coins remaining".
#
# #### Parameters
#
# * string: Text to log
# * args: Additional information
func trace(string: String, args = []):
	if _get_log_level() >= LOG_TRACE and !crashed:
		var argsstr = str(args) if !args.empty() else ""
		string = escoria.esc_compiler.replace_globals(string)
		_log("(T)\t" + string + " \t" + argsstr)


# Log a debug message
#
# Global variables can be substituted into the text by wrapping the global
# name in braces.
# e.g. debug "There are {coin_count} coins remaining".
#
# #### Parameters
#
# * string: Text to log
# * args: Additional information
func debug(string: String, args = []):
	if _get_log_level() >= LOG_DEBUG and !crashed:
		string = escoria.esc_compiler.replace_globals(string)
		var argsstr = str(args) if !args.empty() else ""
		_log("(D)\t" + string + " \t" + argsstr)

# Log an info message
#
# Global variables can be substituted into the text by wrapping the global
# name in braces.
# e.g. info "There are {coin_count} coins remaining".
#
# #### Parameters
#
# * string: Text to log
# * args: Additional information
func info(string: String, args = []):
	if _get_log_level() >= LOG_INFO and !crashed:
		var argsstr = []
		if !args.empty():
			for arg in args:
				if arg is Array:
					for p in arg:
						argsstr.append(p.global_id)
				else:
					argsstr.append(str(arg))
		string = escoria.esc_compiler.replace_globals(string)
		_log("(I)\t" + string + " \t" + str(argsstr))


# Log a warning message
#
# Global variables can be substituted into the text by wrapping the global
# name in braces.
# e.g. warning "There are {coin_count} coins remaining".
#
# #### Parameters
#
# * string: Text to log
# * args: Additional information
func warning(string: String, args = []):
	if _get_log_level() >= LOG_WARNING and !crashed:
		var argsstr = str(args) if !args.empty() else ""
		string = escoria.esc_compiler.replace_globals(string)
		_log("(W)\t" + string + " \t" + argsstr, true)

		if escoria.project_settings_manager.get_setting(
			escoria.project_settings_manager.TERMINATE_ON_WARNINGS
		):
			assert(false)


# Log an error message
#
# Global variables can be substituted into the text by wrapping the global
# name in braces.
# e.g. error "There are {coin_count} coins remaining".
#
# #### Parameters
#
# * string: Text to log
# * args: Additional information
func error(string: String, args = [], do_savegame: bool = true):
	if _get_log_level() >= LOG_ERROR and !crashed:
		var argsstr = str(args) if !args.empty() else ""
		string = escoria.esc_compiler.replace_globals(string)
		_log("(E)\t" + string + " \t" + argsstr, true)

		if escoria.project_settings_manager.get_setting(
			escoria.project_settings_manager.TERMINATE_ON_ERRORS
		):
			assert(false)
	
	func _formatted_date():
		var info = OS.get_datetime()
		info["year"] = "%04d" % info["year"]
		info["month"] = "%02d" % info["month"]
		info["day"] = "%02d" % info["day"]
		info["hour"] = "%02d" % info["hour"]
		info["minute"] = "%02d" % info["minute"]
		info["second"] = "%02d" % info["second"]
		return "{year}-{month}-{day}T{hour}:{minute}:{second}".format(info)
	
	# Returns the currently set log level
	# **Returns** Log level as set in the configuration
	func _get_log_level() -> int:
		return _level_map[ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.LOG_LEVEL
		)]


class ESCLoggerFile extends ESCLoggerBase:
	# Log file handler
	var log_file: File

	# Constructor
	func _init():
		# Open logfile in write mode
		log_file = File.new()

		# this is left alone as this constructor is called from escoria.gd's own
		# constructor
		var log_file_path = ProjectSettings.get_setting(
			ESCProjectSettingsManager.LOG_FILE_PATH
		)
		log_file_path = "res://"
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
		if _get_log_level() >= LOG_TRACE:
			_log_to_file(owner, msg)
			close_file_logs()
			.trace(owner, msg)
	
	# Debug log
	func debug(owner: Object, msg: String):
		if _get_log_level() >= LOG_DEBUG:
			_log_to_file(owner, msg)
			.debug(owner, msg)
	
	func info(owner: Object, msg: String):
		if _get_log_level() >= LOG_INFO:
			_log_to_file(owner, msg)
			.info(owner, msg)

	# Warning log
	func warn(owner: Object, msg: String):
		if _get_log_level() >= LOG_WARNING:
			_log_to_file(owner, msg)
			if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.TERMINATE_ON_WARNINGS
			):
				_log_stack_trace_to_file(owner)
				print_stack()
			close_file_logs()
			.warn(owner, msg)
	
	# Error log
	func error(owner: Object, msg: String):
		if _get_log_level() >= LOG_ERROR:
			_log_to_file(owner, msg)
			if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.TERMINATE_ON_ERRORS
			):
				_log_stack_trace_to_file(owner)
				print_stack()
			close_file_logs()
			.error(owner, msg)
	
	func _log_to_file(owner: Object, msg: String):
		if log_file.is_open():
			var context = ""
			if owner != null:
				context = owner.get_script().resource_path.get_file()
			log_file.store_string(context + " " + msg + "\n")
	
	func _log_stack_trace_to_file(owner: Object):
		var frame_number = 0
		for stack in get_stack().slice(2, get_stack().size()):
			_log_to_file(
				owner,
				"Frame %s - %s:%s in function '%s'" % [
					str(frame_number),
					stack["source"],
					stack["line"],
					stack["function"],
				]
			)
			frame_number += 1

	# Close the log file cleanly
	func close_file_logs():
		print("Closing logs peacefully.")
		_log_to_file(null, "Closing logs peacefully.")
		log_file.close()


class ESCLoggerVerbose extends ESCLoggerBase:
	func _init():
		pass
		
	func debug(owner: Object, msg: String):
		var context = owner.get_script().resource_path.get_file()
		print(context, ": ", msg)

