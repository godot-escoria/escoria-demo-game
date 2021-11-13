# Logging framework for Escoria
extends Object
class_name ESCLogger

# Log file format
const  LOG_FILE_FORMAT: String = "log_%s_%s.log"


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
# #### Parameters
# 
# * string: Text to log
# * args: Additional information
func trace(string: String, args = []):
	if _get_log_level() >= LOG_TRACE and !crashed:
		var argsstr = str(args) if !args.empty() else ""
		_log("(T)\t" + string + " \t" + argsstr)


# Log a debug message
#
# #### Parameters
# 
# * string: Text to log
# * args: Additional information
func debug(string: String, args = []):
	if _get_log_level() >= LOG_DEBUG and !crashed:
		var argsstr = str(args) if !args.empty() else ""
		_log("(D)\t" + string + " \t" + argsstr)


# Log an info message
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
		_log("(I)\t" + string + " \t" + str(argsstr))


# Log a warning message
#
# #### Parameters
# 
# * string: Text to log
# * args: Additional information
func warning(string: String, args = []):
	if _get_log_level() >= LOG_WARNING and !crashed:
		var argsstr = str(args) if !args.empty() else ""
		_log("(W)\t" + string + " \t" + argsstr, true)
		if ProjectSettings.get_setting("escoria/debug/terminate_on_warnings"):
			_perform_stack_trace_log()
			var message: String = ProjectSettings.get_setting(
				"escoria/debug/crash_message"
			) % [
					log_file.get_path_absolute().get_base_dir().plus_file(
						escoria.save_manager.crash_savegame_filename.get_file()
					),
					log_file.get_path_absolute()
				]
			_log("\n" + message + "\n")
			crashed = true
			escoria.quit()
			assert(false)
			


# Log an error message
#
# #### Parameters
# 
# * string: Text to log
# * args: Additional information
func error(string: String, args = [], do_savegame: bool = true):
	if _get_log_level() >= LOG_ERROR and !crashed:
		var argsstr = str(args) if !args.empty() else ""
		_log("(E)\t" + string + " \t" + argsstr, true)
		if ProjectSettings.get_setting("escoria/debug/terminate_on_errors"):
			_perform_stack_trace_log()
			if do_savegame:
				_perform_save_game_log()
			
			var message: String = ProjectSettings.get_setting(
				"escoria/debug/crash_message"
			) % [
					log_file.get_path_absolute().get_base_dir().plus_file(
						escoria.save_manager.crash_savegame_filename.get_file()
					),
					log_file.get_path_absolute()
				]
			_log("\n" + message + "\n")
			crashed = true
			escoria.quit()
			assert(false)


# Log a warning message about an ESC file
#
# #### Parameters
# 
# * p_path: Path to the file
# * warnings: Array of warnings to put out
# * report_once: Additional messages about the same file will be ignored
func report_warnings(p_path: String, warnings: Array, report_once = false) -> void:
	var warning_is_reported = false
	if p_path == warning_path:
		warning_is_reported = true
		
	if !warning_is_reported:
		var text = "Warnings in file "+p_path+"\n"
		for w in warnings:
			if w is Array:
				text += str(w)+"\n"
			else:
				text += w+"\n"
		warning(text)
	
		if report_once:
			warning_is_reported = true


# Log an error message about an ESC file
#
# #### Parameters
# 
# * p_path: Path to the file
# * errors: Array of errors to put out
func report_errors(p_path: String, errors: Array) -> void:
	var text = "Errors in file "+p_path+"\n"
	for e in errors:
		if e is Array:
			text += str(e)+"\n"
		else:
			text += e+"\n"
	error(text)


# Write message:
# - in logfile
# - in stdout, or stderr if err is true.
#
# #### Parameters
# 
# * message: Message to log
# * err: if true, write in stderr
func _log(message:String, err: bool = false):
	if err:
		printerr(message)
	else:
		print(message)
	_write_logfile(message)


# Returns the currently set log level
# **Returns** Log level as set in the configuration
func _get_log_level() -> int:
	return _level_map[ProjectSettings.get_setting("escoria/debug/log_level")]


# Creates a savegame file and save it in output log location
func _perform_save_game_log():
	_log("Performing emergency savegame.")
	var error = escoria.save_manager.save_game_crash()
	if error == OK:
		_log(
			"Emergency savegame created successfully in folder: %s" %
				ProjectSettings.get_setting(
					"escoria/debug/log_file_path"
				)
		)
	else:
		_log("Emergency savegame creation failed!", false)


# Logs and writes the stack trace into stdout and log file.
func _perform_stack_trace_log():
	_log("Stack trace:")
	print_stack()
	_write_stack_logfile()


# Write a message in the output logfile
#
# #### Parameters
# 
# * message: Message to write
func _write_logfile(message: String) -> void:
	if log_file.is_open():
		log_file.store_string(message + "\n")


# Write the stacktrace in the output logfile
func _write_stack_logfile():
	var frame_number = 0
	for stack in get_stack().slice(2, get_stack().size()):
		_write_logfile(
			"Frame %s - %s:%s in function '%s'" % [
				str(frame_number),
				stack["source"],
				stack["line"],
				stack["function"],
			]
		)
		frame_number += 1


# Close the log file cleanly
func close_logs():
	_log("Closing logs peacefully.")
	log_file.close()
