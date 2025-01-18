# This static class is primarily for situations where there's a possibility that logging to the 
# console may be done by a tool script, and so won't have access to the autoloader/singleton that is
# `escoria`.
class_name ESCSafeLogging


const COLOUR_RED = "red"
const COLOUR_GREEN = "green"
const COLOUR_YELLOW = "yellow"


static func log_level() -> String:
	return ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.LOG_LEVEL
		).to_upper()


static func log_error(owner: Object, message: String) -> void:
	if Engine.is_editor_hint() and ESCLogLevel.determine_escoria_log_level() >= ESCLogLevel.LOG_ERROR:
		print_rich("[color=%s]%s[/color]" % [COLOUR_RED, message])
	else:
		escoria.logger.error(owner, message)


static func log_warn(owner: Object, message: String) -> void:
	if Engine.is_editor_hint() and ESCLogLevel.determine_escoria_log_level() >= ESCLogLevel.LOG_WARNING:
		print_rich("[color=%s]%s[/color]" % [COLOUR_YELLOW, message])
	else:
		escoria.logger.warn(owner, message)


static func log_debug(owner: Object, message: String) -> void:
	if Engine.is_editor_hint() and ESCLogLevel.determine_escoria_log_level() >= ESCLogLevel.LOG_DEBUG:
		print(message)
	else:
		escoria.logger.debug(owner, message)


static func log_trace(owner: Object, message: String) -> void:
	if Engine.is_editor_hint() and ESCLogLevel.determine_escoria_log_level() >= ESCLogLevel.LOG_TRACE:
		print(message)
	else:
		escoria.logger.trace(owner, message)


# Doesn't correpond to a logging level for offline logging; meant more for messages conveying a result
static func log_result(owner: Object, message: String, is_successful_result: bool) -> void:
	var colour: String = COLOUR_GREEN if is_successful_result else COLOUR_RED

	if Engine.is_editor_hint():
		print_rich("[color=%s]%s[/color]" % [colour, message])
	else:
		escoria.logger.info(owner, message)
