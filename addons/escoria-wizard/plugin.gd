@tool
extends EditorPlugin

const helper_ui = preload("res://addons/escoria-wizard/escoria_wizard.tscn")

# This is the instance of the plugin code that is instantiated by the plugin.
var helper_instance

func _enter_tree() -> void:
	helper_instance = helper_ui.instance()
	helper_instance.plugin_reference = self
	# Add the panel to the main viewport
	get_editor_interface().get_editor_main_screen().add_child(helper_instance)
	_make_visible(false)


func _exit_tree() -> void:
	if helper_instance:
		helper_instance.queue_free()


func _has_main_screen() -> bool:
	# Add the button to the Godot interface ribbon
	return true


func _make_visible(visible: bool) -> void:
	if helper_instance:
		helper_instance.visible = visible


func _get_plugin_name() -> String:
	return "Escoria Wizard"


func _get_plugin_icon() -> Texture2D:
	return (preload("res://addons/escoria-wizard/graphics/icon16x16.png"))


func open_scene(path: String) -> void:
	get_editor_interface().open_scene_from_path(path)

# Unregister ourselves
func _disable_plugin():
	print("Disabling Escoria Wizard plugin")
	ESCProjectSettingsManager.remove_setting(
		"escoria/wizard/path_to_rooms"
	)

# Register ourselves
func _enable_plugin():
	print("Enabling Escoria Wizard plugin")
	ESCProjectSettingsManager.register_setting(
		"escoria/wizard/path_to_rooms",
		"res://rooms",
		{
			"type": TYPE_STRING
		}
	)
