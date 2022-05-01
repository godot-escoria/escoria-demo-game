# An ESC command
extends ESCStatement
class_name ESCCommand


# Regex matching command lines
const REGEX = \
	'^(\\s*)(?<name>[^\\s]+)(\\s(?<parameters>([^\\[]|$)+))?' +\
	'(\\[(?<conditions>[^\\]]+)\\])?'


# The name of this command
var name: String

# Parameters of this command
var parameters: Array = []

# A list of ESCConditions to run this command.
# Conditions are combined using logical AND
var conditions: Array = []


# Create a command from a command string
func _init(command_string):
	var command_regex = RegEx.new()
	command_regex.compile(REGEX)

	if command_regex.search(command_string):
		for result in command_regex.search_all(command_string):
			if "name" in result.names:
				self.name = escoria.utils.get_re_group(result, "name")
			if "parameters" in result.names:
				# Split parameters by whitespace but allow quoted
				# parameters
				var quote_open = false
				var parameter_values = PoolStringArray([])
				var parsed_parameters = \
					escoria.utils.sanitize_whitespace(
						escoria.utils.get_re_group(
							result,
							"parameters"
						).strip_edges()
					)
				for parameter in parsed_parameters.split(" "):
					if parameter.begins_with('"') and parameter.ends_with('"'):
						parameters.append(
							parameter
						)
					elif ":" in parameter and '"' in parameter:
						quote_open = true
						parameter_values.append(parameter)
					elif parameter.begins_with('"'):
						quote_open = true
						parameter_values.append(parameter)
					elif parameter.ends_with('"'):
						quote_open = false
						parameter_values.append(
							parameter.substr(0, len(parameter))
						)
						parameters.append(parameter_values.join(" "))
						parameter_values.resize(0)
					elif quote_open:
						parameter_values.append(parameter)
					else:
						parameters.append(parameter)
			if "conditions" in result.names:
				for condition in escoria.utils.get_re_group(
							result,
							"conditions"
						).split(","):
					self.conditions.append(
						ESCCondition.new(condition.strip_edges())
					)
	else:
		escoria.logger.report_errors(
			"Invalid command detected: %s" % command_string,
			[
				"Command regexp didn't match"
			]
		)


# Check, if conditions match
func is_valid() -> bool:
	if not command_exists():
		escoria.logger.report_errors(
			"Invalid command detected: %s" % self.name,
			[
				"Command implementation not found in any command directory"
			]
		)
		return false

	return .is_valid()


# Checks that the command exists
#
# *Returns* True if the command exists, else false.
func command_exists() -> bool:
	for base_path in escoria.project_settings_manager.get_setting(
			escoria.project_settings_manager.COMMAND_DIRECTORIES
		):
		var command_path = "%s/%s.gd" % [
			base_path.trim_suffix("/"),
			self.name
		]
		if ResourceLoader.exists(command_path):
			return true
	return false


# Run this command
func run() -> int:
	var command_object = escoria.command_registry.get_command(self.name)
	if command_object == null:
		return ESCExecution.RC_ERROR
	else:
		var argument_descriptor = command_object.configure()
		var prepared_arguments = argument_descriptor.prepare_arguments(
			self.parameters
		)

		if command_object.validate(prepared_arguments):
			escoria.logger.debug("Running command %s with parameters %s" % [
				self.name,
				prepared_arguments
			])
			var rc = command_object.run(prepared_arguments)
			if rc is GDScriptFunctionState:
				rc = yield(rc, "completed")
			escoria.logger.debug("[%s] Return code: %d" % [self.name, rc])
			return rc
		else:
			return ESCExecution.RC_ERROR


# This function interrupts the command. If it was not started, it will not run.
# If it had already started, the execution will be considered as finished
# immediately and finish. If it was already finished, nothing will happen.
func interrupt():
	_is_interrupted = true
	var command = escoria.command_registry.get_command(self.name)
	if command.has_method("interrupt"):
		command.interrupt()


# Override of built-in _to_string function to display the statement.
func _to_string() -> String:
	return "Command %s with parameters: %s" % [name, str(parameters)]

