@tool
extends Node
class_name ESCAshesAnalyzer


# TODO: Update this when we move from the .esc extension for Escoria scripts to .ash
const FILE_EXTENSION_ASHES = "esc"


var _compiler: ESCCompiler = ESCCompiler.new()


func analyze() -> void:
	var dir = DirAccess.open("res://game/rooms/room11/esc")

	if dir:
		dir.list_dir_begin()
	else:
		print(DirAccess.get_open_error())

	var filename: String = dir.get_next()

	while not filename.is_empty():
		if dir.current_is_dir() or filename.get_extension() != FILE_EXTENSION_ASHES:
			continue

		var filename_with_path: String = dir.get_current_dir() + "/" + filename

		_compiler.load_esc_file(filename_with_path)

		filename = dir.get_next()
