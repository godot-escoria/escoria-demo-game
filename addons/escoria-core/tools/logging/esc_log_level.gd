class_name ESCLogLevel


# Valid log levels
enum { LOG_ERROR, LOG_WARNING, LOG_INFO, LOG_DEBUG, LOG_TRACE }


# A map of log level names to log level ints
const LEVEL_MAP: Dictionary = {
	"ERROR": LOG_ERROR,
	"WARNING": LOG_WARNING,
	"INFO": LOG_INFO,
	"DEBUG": LOG_DEBUG,
	"TRACE": LOG_TRACE,
}


static func determine_escoria_log_level():
	return LEVEL_MAP[ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.LOG_LEVEL
		).to_upper()]
