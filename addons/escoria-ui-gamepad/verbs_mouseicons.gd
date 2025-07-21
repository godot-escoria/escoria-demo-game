extends Control


var current_cursor_id: int = 0
@onready var cursors: Array = $actions.get_children()

@onready var action_manually_changed = false


func _ready():
	if !Engine.is_editor_hint():
		current_cursor_id = cursors.size()
		set_by_name("walk")
		set_process(false)

func _process(delta):
	$mouse_position.global_position = get_global_mouse_position()


func iterate_actions_cursor(direction: int):
	current_cursor_id += direction
	if current_cursor_id > 4:
		current_cursor_id = 0
	elif current_cursor_id < 0:
		current_cursor_id = 4
	set_by_name(cursors[current_cursor_id].name)
	if $mouse_position/tool.texture != null:
		clear_tool_texture()
	action_manually_changed = true


func set_by_name(name: String, force_verb: String = "") -> void:
	for i in cursors.size():
		if cursors[i].name == name:
			current_cursor_id = i
			break

	Input.set_custom_mouse_cursor(
		cursors[current_cursor_id].texture,
		Input.CURSOR_ARROW,
		Vector2(32,32)
	)
	if force_verb.is_empty():
		escoria.action_manager.set_current_action(cursors[current_cursor_id].name)
	else:
		escoria.action_manager.set_current_action(force_verb)

func set_tool_texture(texture: Texture2D):
	set_process(true)
	$mouse_position/tool.texture = texture

func clear_tool_texture():
	$mouse_position/tool.texture = null
	set_process(false)
