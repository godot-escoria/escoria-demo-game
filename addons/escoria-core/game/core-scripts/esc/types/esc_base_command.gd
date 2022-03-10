# A base class for every ESC command.
# Extending classes have to override the configure and run function
extends Node
class_name ESCBaseCommand


# Regex for creating command name based on the script's filename, including
# named groups
const PATH_REGEX_GROUP = "path"
const FILE_REGEX_GROUP = "file"
const EXTENSION_REGEX_GROUP = "extension"
const COMMAND_NAME_REGEX = "(?<%s>.+)\/(?<%s>[^.]+)(?<%s>\\.[^.]*$|$)" % \
	[PATH_REGEX_GROUP, FILE_REGEX_GROUP, EXTENSION_REGEX_GROUP]

# Regex matcher for command names
var command_name_regex: RegEx = RegEx.new()


func _init() -> void:
	command_name_regex.compile(COMMAND_NAME_REGEX)


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	escoria.logger.error("Command %s did not override configure." % get_class())
	return ESCCommandArgumentDescriptor.new()


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array) -> bool:
	return self.configure().validate(get_class(), arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.logger.error("Command %s did not override run." % get_class())
	return 0


# Return the name of the command based on the script's filename
func get_command_name() -> String:
	return command_name_regex.search(get_script().get_path()).get_string(FILE_REGEX_GROUP)
