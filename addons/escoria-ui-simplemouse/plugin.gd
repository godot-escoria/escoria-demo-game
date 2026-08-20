@tool
# Plugin script to initialize Escoria simple mouse UI
extends EditorPlugin

const ESC_CHANGE_VERB_CREATED_SETTING = "escoria/internal/esc_change_verb_created_by_simplemouse_plugin"


# Override function to return the plugin name.
func _get_plugin_name():
	return "escoria-ui-simplemouse"


# Deregister UI
func _disable_plugin():
	print("Disabling plugin Escoria UI Simple Mouse.")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-simplemouse/game.tscn")

	var action_path := "input/" + SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION
	var action_setting = ProjectSettings.get(action_path)
	var created_by_plugin: bool = ProjectSettings.get_setting(
		ESC_CHANGE_VERB_CREATED_SETTING,
		false
	)

	if created_by_plugin and action_setting:
		InputMap.erase_action(SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION)
		ProjectSettings.set_setting(action_path, null)

	if created_by_plugin:
		ProjectSettings.set_setting(ESC_CHANGE_VERB_CREATED_SETTING, false)
		ProjectSettings.save()


# Register UI with Escoria
func _enable_plugin():
	print("Enabling plugin Escoria UI Simple Mouse.")
	if not EscoriaPlugin.register_ui(self, "res://addons/escoria-ui-simplemouse/game.tscn"):
		get_editor_interface().set_plugin_enabled(
			_get_plugin_name(),
			false
		)

	var action_path := "input/" + SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION
	var action_setting = ProjectSettings.get(action_path)

	if not action_setting:
		InputMap.add_action(SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION)
		ProjectSettings.set_setting(action_path,
		{
			"deadzone": 0.2,
			"events": []
		})
		ProjectSettings.set_setting(ESC_CHANGE_VERB_CREATED_SETTING, true)
		ProjectSettings.save()
	else:
		# Existing project mapping: mark as not plugin-created so disable won't erase it.
		if ProjectSettings.get_setting(ESC_CHANGE_VERB_CREATED_SETTING, false):
			ProjectSettings.set_setting(ESC_CHANGE_VERB_CREATED_SETTING, false)
		ProjectSettings.save()
