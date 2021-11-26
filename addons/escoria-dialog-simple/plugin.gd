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
	_escoria.register_setting(
		"escoria/dialog_simple/avatars_path",
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)
	
	_escoria.register_setting(
		"escoria/dialog_simple/text_speed_per_character",
		0.1,
		{
			"type": TYPE_REAL
		}
	)
	
	_escoria.register_setting(
		"escoria/dialog_simple/fast_text_speed_per_character",
		0.25,
		{
			"type": TYPE_REAL
		}
	)
	
	_escoria.register_setting(
		"escoria/dialog_simple/max_time_to_disappear",
		1.0,
		{
			"type": TYPE_REAL
		}
	)
