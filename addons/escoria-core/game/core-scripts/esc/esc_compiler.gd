## Compiler for the ASHES language.
extends Resource
class_name ESCCompiler


## This must match `ESCProjectSettingsManager.COMMAND_DIRECTORIES`.
## We do not reference it directly in order to avoid circular dependencies.
const COMMAND_DIRECTORIES = "escoria/main/command_directories"


## Whether an error has been encountered during the compilation process.
var had_error: bool = false

## Initialize the ESCCompiler and assure command list preference.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
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


## Static method to pre-load all ASHES commands from `ESCProjectSettingsManager.COMMAND_DIRECTORIES`. All commands must extend `ESCBaseCommand`.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `Array` value. (`Array`)
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
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `Dictionary` value. (`Dictionary`)
static func load_globals() -> Dictionary:
	var globals: Dictionary = {}

	for obj in ESCObjectManager.RESERVED_OBJECTS:
		globals[obj] = obj

	for obj in ESCRoomManager.RESERVED_GLOBALS:
		globals[obj] = ESCRoomManager.RESERVED_GLOBALS[obj]

	return globals


## Compile the given ESC source code into an ESCScript object.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |source|`String`|The ESC source code to compile.|yes|[br]
## |filename|`String`|Optional filename for error reporting.|no|[br]
## |associated_global_id|`String`|Optional global id associated with the script.|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns an `ESCScript` object representing the compiled script.
func _compiler_shim(source: String, filename: String = "", associated_global_id: String = ""):
	var scanner: ESCScanner = ESCScanner.new()
	scanner.set_source(source)
	scanner.set_filename(filename)
	had_error = false

	var tokens = scanner.scan_tokens()

	var parser: ESCParser = ESCParser.new()
	parser.init(self, tokens, associated_global_id)

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
			var event_name = ps.get_event_name()
			if ps.get_target() != null:
				event_name += " " + ps.get_target_name()
			script.events[event_name] = ps
	return script


## Load an ESC file from a file resource. We also accept an optional global ID of whatever object is associated with the ESC file. Note that we don't need to do the same for a room-attached script since the current room's global_id is always available as an Escoria global.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |path|`String`|the path of the script file to load|yes|[br]
## |associated_global_id|`String`|global ID of the object/room associated with the script file, if any (may be empty)|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `ESCScript` value. (`ESCScript`)
func load_esc_file(path: String, associated_global_id: String = "") -> ESCScript:
	ESCSafeLogging.log_debug(self, "Loading file '%s' for parsing..." % path)

	if not FileAccess.file_exists(path):
		ESCSafeLogging.log_error(self, "Unable to find ESC file: '%s' could not be found." % path)

		return null

	var file = FileAccess.open(path, FileAccess.READ)

	return _compiler_shim(file.get_as_text(), path, associated_global_id)


## Compiles the passed-in script. TODO: `path` is extraneous and left in for legacy purposes; at some point, this will be removed which will require updating other methods that reference this one to ensure they don't pass in a second argument.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |script|`String`|A `String` containing the entirety of the script to be compiled.|yes|[br]
## |path|`String`|NOT USED.|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `ESCScript` value. (`ESCScript`)
func compile(script: String, path: String = "") -> ESCScript:
	return _compiler_shim(script)


## True if this is being called in-editor or the appropriate project setting is enabled.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns true if this is being called in-editor or the appropriate project setting is enabled. (`bool`)
func _run_script_analysis() -> bool:
	if Engine.is_editor_hint():
		return true

	return ProjectSettings.get_setting(ESCProjectSettingsManager.PERFORM_SCRIPT_ANALYSIS_AT_RUNTIME)
