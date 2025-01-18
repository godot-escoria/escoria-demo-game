@tool
extends Node
class_name ESCAshesAnalyzer


# TODO: Update this when we move from the .esc extension for Escoria scripts to .ashes
const FILE_EXTENSION_ASHES = "esc"


var _compiler: ESCCompiler = ESCCompiler.new()


func analyze() -> void:
	#if not _current_script_is_ashes():
	#	return

	print("TODO: Test against ENTIRE project scan for ESC files.")
	var dir = DirAccess.open("res://game/rooms/room11/esc")

	if dir:
		dir.list_dir_begin()

	var filename: String = dir.get_next()

	while not filename.is_empty():
		if dir.current_is_dir() or filename.get_extension() != FILE_EXTENSION_ASHES:
			continue

		var filename_with_path: String = dir.get_current_dir() + "/" + filename

		_compiler.load_esc_file(filename_with_path)

		filename = dir.get_next()


func _current_script_is_ashes() -> bool:
	return _get_extension_of_script_being_edited() == FILE_EXTENSION_ASHES


func _get_extension_of_script_being_edited() -> String:
	return EditorInterface.get_script_editor().get_current_script().resource_path.get_extension()


func _get_script_body() -> String:
	return EditorInterface.get_script_editor().get_current_script().source_code
