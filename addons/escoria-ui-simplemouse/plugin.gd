@tool
# Plugin script to initialize Escoria simple mouse UI
extends EditorPlugin


# Override function to return the plugin name.
func _get_plugin_name():
	return "escoria-ui-simplemouse"


# Deregister UI
func _disable_plugin():
	print("Disabling plugin Escoria UI Simple Mouse.")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-simplemouse/game.tscn")
	
	if ProjectSettings.get("input/"+SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION):
		InputMap.erase_action(SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION)
		ProjectSettings.set_setting("input/" + SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION, null)
		ProjectSettings.save()


# Register UI with Escoria
func _enable_plugin():
	print("Enabling plugin Escoria UI Simple Mouse.")
	if not EscoriaPlugin.register_ui(self, "res://addons/escoria-ui-simplemouse/game.tscn"):
		get_editor_interface().set_plugin_enabled(
			_get_plugin_name(),
			false
		)

	if not ProjectSettings.get("input/"+SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION):
		InputMap.add_action(SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION)
		ProjectSettings.set_setting("input/" + SimpleMouseConstants.ESC_UI_CHANGE_VERB_ACTION, 
		{
			"deadzone": 0.2,
			"events": []
		})
		ProjectSettings.save()
