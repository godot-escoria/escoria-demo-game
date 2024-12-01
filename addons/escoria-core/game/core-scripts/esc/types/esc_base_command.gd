# A base class for every ESC command.
# Extending classes have to override the configure and run function
extends Resource
class_name ESCBaseCommand


# Regex for creating command name based on the script's filename, including
# named groups
const PATH_REGEX_GROUP = "path"
const FILE_REGEX_GROUP = "file"
const EXTENSION_REGEX_GROUP = "extension"
const COMMAND_NAME_REGEX = "(?<" + PATH_REGEX_GROUP + ">.+)\\/(?<" \
	+ FILE_REGEX_GROUP + ">[^.]+)(?<" + EXTENSION_REGEX_GROUP + ">.[^.]*$|$)"

# Regex matcher for command names
var command_name_regex: RegEx = RegEx.new()

# The filename from which the relevant command is being called, if available.
var filename: String = ""

# The line number from the file the relevant command is being called from.
var line_number: int = 0


func _init() -> void:
	command_name_regex.compile(COMMAND_NAME_REGEX)


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	escoria.logger.error(
		self,
		"Command %s did not override configure. Please implement a configure() function." % get_command_name()
	)
	return ESCCommandArgumentDescriptor.new()


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array) -> bool:
	var argument_descriptor = self.configure()

	argument_descriptor.filename = filename
	argument_descriptor.line_number = line_number

	return argument_descriptor.validate(get_command_name(), arguments)


# Run the command
func run(command_params: Array) -> int:
	raise_error(self, "Command %s did not override run. Please implement a run() function." % get_command_name())

	return 0


# Return the name of the command based on the script's filename
func get_command_name() -> String:
	var path := get_script().get_path() as String
	
	return path.get_basename().get_file()
	
	# FIXME: This did not work for some paths although it should
	#return command_name_regex.search(path).get_string(FILE_REGEX_GROUP)


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"Command %s did not override interrupt. Please implement an interrupt() function." % get_command_name()
	)


func raise_error(command, message: String) -> void:
	escoria.logger.error(
		command,
		"[%s]: %s %s" % [get_command_name(), message, _get_error_info()]
	)


# Raises an error specific to no object being found with `global_id` as its identifier.
# `command` is the actual command implementation generating the error.
func raise_invalid_object_error(command, global_id: String) -> void:
	raise_error(command, "Invalid object. Object with global id %s not found." % global_id)


func _get_error_info() -> String:
	return "(File: \"%s\", line %s.)" % [filename, line_number]
