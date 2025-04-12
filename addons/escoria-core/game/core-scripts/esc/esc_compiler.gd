## Compiler for the ASHES language.
extends Resource
class_name ESCCompiler


## This must match `ESCProjectSettingsManager.COMMAND_DIRECTORIES`.
## We do not reference it directly in order to avoid circular dependencies.
const COMMAND_DIRECTORIES = "escoria/main/command_directories"


## Whether an error has been encountered during the compilation process.
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


## Static method to pre-load all ASHES commands from 
## `ESCProjectSettingsManager.COMMAND_DIRECTORIES`. All commands must extend 
## `ESCBaseCommand`.[br]
##[br]
## **Returns** an array containing the commands as loaded resources.
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


## Static method to load all Escoria reserved objects and reserved globals.[br]
##[br]
## **Returns** a `Dictionary` containing all reserved objects and reserved globals.
static func load_globals() -> Dictionary:
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

	if not filename.is_empty():
		var error_message: String = ("Error(s) found during parsing" if had_error else "No errors found during parsing") + ("" if filename.is_empty() else " of script '%s'" % filename)

		ESCSafeLogging.log_result(self, error_message, not had_error)

	# Some static analysis
	if not had_error and _run_script_analysis():
		var resolver: ESCResolver = ESCResolver.new(ESCInterpreterFactory.create_interpreter())
		resolver.resolve(parsed_statements)

		if not filename.is_empty():
			ESCSafeLogging.log_info(self, "Analyzing '%s'..." % filename)

			var static_analyzers = ESCStaticAnalyzers.new(parsed_statements)
			static_analyzers.run()

			ESCSafeLogging.log_info(self, "Finished analyzing '%s'." % filename)

	var script = ESCScript.new()

	script.filename = filename

	if not had_error:
		for ps in parsed_statements:
			script.events[ps.get_event_name()] = ps

	return script
	#if not had_error:
	#	interpreter.interpret(parsed_statements)


## Load an ESC (ASHES) file from a file resource.[br]
##[br]
## **Returns** a valid `ESCScript` containing the parsed statements found in 
## `path`.
func load_esc_file(path: String) -> ESCScript:
	ESCSafeLogging.log_debug(self, "Loading file '%s' for parsing..." % path)

	if not FileAccess.file_exists(path):
		ESCSafeLogging.log_error(self, "Unable to find ESC file: '%s' could not be found." % path)

		return null

	var file = FileAccess.open(path, FileAccess.READ)

	return _compiler_shim(file.get_as_text(), path)


## Compiles the passed-in script.[br]
##[br]
## TODO: `path` is extraneous and left in for legacy purposes; at some point, this will be removed 
## which will require updating other methods that reference this one to ensure they don't pass in
## a second argument.[br]
##[br]
## #### Parameters ####[br]
## * script: A `String` containing the entirety of the script to be compiled.[br]
## * path: NOT USED.
func compile(script: String, path: String = "") -> ESCScript:
	return _compiler_shim(script)


# *Returns*
# true iff this is being called in-editor or the appropriate project setting is enabled
func _run_script_analysis() -> bool:
	if Engine.is_editor_hint():
		return true

	return ProjectSettings.get_setting(ESCProjectSettingsManager.ENABLE_HOVER_STACK_VIEWER)
