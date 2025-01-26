# Compiler of the ESC language
extends Resource
class_name ESCCompiler


# This must match ESCProjectSettingsManager.COMMAND_DIRECTORIES.
# We do not reference it directly to avoid circular dependencies.
const COMMAND_DIRECTORIES = "escoria/main/command_directories"

# The currently compiled event
var _current_event = null

# A stack of groups currently compiling
var _groups_stack = []

# A stack of dialogs currently compiling
var _dialogs_stack = []

# A stack of dialog options currently compiling
var _dialogs_option_stack = []

# A pointer to the current container (group, dialog option)
# that should get the current command
var _command_container = []

# The currently identified indent
var _current_indent = 0

# Cache the list of ESC commands available
var _commands: Array = []

var had_error: bool = false


func _init():
	# Assure command list preference
	# (we use ProjectSettings instead of ESCProjectSettingsManager
	# here because this is called from escoria._init())
	if not ProjectSettings.has_setting(COMMAND_DIRECTORIES):
		ProjectSettings.set_setting(COMMAND_DIRECTORIES, [
			"res://addons/escoria-core/game/core-scripts/esc/commands"
		])
		var property_info = {
			"name": COMMAND_DIRECTORIES,
			"type": TYPE_PACKED_STRING_ARRAY
		}
		ProjectSettings.add_property_info(property_info)


static func load_commands() -> Array:
	var commands: Array = []

	for command_directory in ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.COMMAND_DIRECTORIES
	):
		var dir = DirAccess.open(command_directory)
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name:
			if ResourceLoader.exists("%s/%s" % [command_directory, file_name]):
				commands.append(load(
					"%s/%s" % [
						command_directory.trim_suffix("/"),
						file_name
					]
				).new())

			file_name = dir.get_next()

	return commands


static func load_globals():
	var globals: Dictionary = {}

	for obj in ESCObjectManager.RESERVED_OBJECTS:
		globals[obj] = obj

	for obj in ESCRoomManager.RESERVED_GLOBALS:
		globals[obj] = ESCRoomManager.RESERVED_GLOBALS[obj]

	return globals


func _compiler_shim(source: String, filename: String = ""):
	var scanner: ESCScanner = ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(filename)
	had_error = false

	var tokens = scanner.scan_tokens()

	var parser: ESCParser = ESCParser.new()
	parser.init(self, tokens)

	var parsed_statements = parser.parse()

	var error_message: String = ("Error(s) found during parsing" if had_error else "No errors found during parsing") + ("" if filename.is_empty() else " of script '%s'" % filename)

	ESCSafeLogging.log_result(self, error_message, not had_error)

	# Some static analysis
	if not had_error:
		var resolver: ESCResolver = ESCResolver.new(ESCInterpreterFactory.create_interpreter())
		resolver.resolve(parsed_statements)

		var static_analyzers = ESCStaticAnalyzers.new(parsed_statements)
		static_analyzers.run()

	var script = ESCScript.new()

	script.filename = filename

	if not had_error:
		for ps in parsed_statements:
			script.events[ps.get_event_name()] = ps

	return script
	#if not had_error:
	#	interpreter.interpret(parsed_statements)


# Load an ESC file from a file resource
func load_esc_file(path: String) -> ESCScript:
	ESCSafeLogging.log_debug(self, "Loading file '%s' for parsing..." % path)

	if not FileAccess.file_exists(path):
		ESCSafeLogging.log_error(self, "Unable to find ESC file: '%s' could not be found." % path)

		return null

	var file = FileAccess.open(path, FileAccess.READ)

	return _compiler_shim(file.get_as_text(), path)


func compile(script: String, path: String = "") -> ESCScript:
	return _compiler_shim(script)
