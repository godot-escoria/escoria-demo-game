@tool
# Plugin script to initialize Escoria simple mouse cycle UI
extends EditorPlugin


func _get_plugin_name():
	return "escoria-ui-simplemouse-cycle"


func _disable_plugin():
	print("Disabling plugin Escoria UI Simple Mouse Cycle.")
	if ESCProjectSettingsManager.has_setting(SimpleMouseCycleUISettings.SHOW_VERB_CURSOR):
		ESCProjectSettingsManager.remove_setting(
			SimpleMouseCycleUISettings.SHOW_VERB_CURSOR
		)
	if ESCProjectSettingsManager.has_setting(SimpleMouseCycleUISettings.SHOW_VERB_IN_TOOLTIP):
		ESCProjectSettingsManager.remove_setting(
			SimpleMouseCycleUISettings.SHOW_VERB_IN_TOOLTIP
		)
	if ESCProjectSettingsManager.has_setting(SimpleMouseCycleUISettings.DIALOG_CHOICE_CURSOR):
		ESCProjectSettingsManager.remove_setting(
			SimpleMouseCycleUISettings.DIALOG_CHOICE_CURSOR
		)
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-simplemouse-cycle/game.tscn")


func _enable_plugin():
	print("Enabling plugin Escoria UI Simple Mouse Cycle.")
	if not EscoriaPlugin.register_ui(self, "res://addons/escoria-ui-simplemouse-cycle/game.tscn"):
		get_editor_interface().set_plugin_enabled(
			_get_plugin_name(),
			false
		)
		return

	ESCProjectSettingsManager.register_setting(
		SimpleMouseCycleUISettings.SHOW_VERB_CURSOR,
		true,
		{
			"type": TYPE_BOOL
		}
	)
	ESCProjectSettingsManager.register_setting(
		SimpleMouseCycleUISettings.SHOW_VERB_IN_TOOLTIP,
		true,
		{
			"type": TYPE_BOOL
		}
	)
	ESCProjectSettingsManager.register_setting(
		SimpleMouseCycleUISettings.DIALOG_CHOICE_CURSOR,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.png,*.svg,*.webp,*.jpg,*.jpeg"
		}
	)
