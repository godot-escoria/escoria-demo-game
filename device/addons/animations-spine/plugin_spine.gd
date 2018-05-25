tool
extends EditorPlugin

func _enter_tree():
    add_autoload_singleton(get_singleton_name(), "res://addons/animations-spine/animations_spine.gd")
    pass

func _exit_tree():
    remove_autoload_singleton(get_singleton_name())
    pass

func handles(object):
	return object.get_class() in managed_types()

func get_name():
	return "animations-spine"

func get_singleton_name():
	return get_name().replace("-","_")

func managed_types():
	return [ "Spine" ]
