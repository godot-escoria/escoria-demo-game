class_name ESCLogLevel
## Log levels for ESCLogger.

## Valid log levels by order of granularity (E, W, I, D, T)
enum {
	LOG_ERROR,
	LOG_WARNING,
	LOG_INFO,
	LOG_DEBUG,
	LOG_TRACE
}


## A map of log level names to log level ints
const LEVEL_MAP: Dictionary = {
	"ERROR": LOG_ERROR,
	"WARNING": LOG_WARNING,
	"INFO": LOG_INFO,
	"DEBUG": LOG_DEBUG,
	"TRACE": LOG_TRACE,
}

## Static function to determine the int log level value defined in Project Settings (Escoria>Debug>Log Level)[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `int` value. (`int`)
static func determine_escoria_log_level() -> int:
	return LEVEL_MAP[ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.LOG_LEVEL
		).to_upper()]
