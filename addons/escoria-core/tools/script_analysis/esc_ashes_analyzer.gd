@tool
extends Node
class_name ESCAshesAnalyzer


# TODO: Update this when we move from the .esc extension for Escoria scripts to .ash
const FILE_EXTENSION_ASHES = "esc"
const DIRECTORIES_TO_EXCLUDE = ["addons"]


var _compiler: ESCCompiler = ESCCompiler.new()


func analyze() -> void:
	var files: Array[String] = _get_script_files_recursive("res://")

	files.sort()

	for file in files:
		_compiler.load_esc_file(file)


func _get_script_files_recursive(path: String, files: Array[String] = []) -> Array[String]:
	var dir = DirAccess.open(path)

	if dir:
		dir.list_dir_begin()
	else:
		ESCSafeLogging.log_warn(self, "Unable to open '%s'." % path)
		return files

	var filename: String = dir.get_next()

	while not filename.is_empty():
		var filename_with_path: String = _make_full_path(dir.get_current_dir(), filename)

		if dir.current_is_dir() and not filename in DIRECTORIES_TO_EXCLUDE:
			files = _get_script_files_recursive(filename_with_path, files)
		else:
			if filename.get_extension() == FILE_EXTENSION_ASHES:
				files.append(filename_with_path)

		filename = dir.get_next()

	return files


func _make_full_path(directory: String, filename: String) -> String:
	var separator: String = "" if directory.ends_with("/") else "/"

	return directory + separator + filename
