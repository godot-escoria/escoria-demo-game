# A simple dialog manager for Escoria
tool
extends EditorPlugin


var _escoria

const MANAGER_CLASS="res://addons/escoria-dialog-simple/esc_dialog_simple.gd"


func _init() -> void:
	 _escoria = preload("res://addons/escoria-core/game/escoria.tscn")\
			.instance()


# Register ourselves after setup
func _ready() -> void:
	call_deferred("_register")
	

# Unregister ourselves
func _exit_tree() -> void:
	_escoria.deregister_dialog_manager(MANAGER_CLASS)


# Add ourselves to the list of dialog managers
func _register():
	_escoria.register_dialog_manager(MANAGER_CLASS)
	_escoria.project_settings_manager.register_setting(
		_escoria.project_settings_manager.AVATARS_PATH,
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)
	
	_escoria.project_settings_manager.register_setting(
		_escoria.project_settings_manager.TEXT_SPEED_PER_CHARACTER,
		0.1,
		{
			"type": TYPE_REAL
		}
	)
	
	_escoria.project_settings_manager.register_setting(
		_escoria.project_settings_manager.FAST_TEXT_SPEED_PER_CHARACTER,
		0.25,
		{
			"type": TYPE_REAL
		}
	)
	
	_escoria.project_settings_manager.register_setting(
		_escoria.project_settings_manager.MAX_TIME_TO_DISAPPEAR,
		1.0,
		{
			"type": TYPE_REAL
		}
	)
