extends Control


var current_cursor_id: int = 0
onready var cursors: Array = $actions.get_children()


"""
This script is out of Escoria's scope. It controls the UI reaction to an
UI event (eg right click) to change the cursor accordingly.
"""
enum UI_ACTIONS_DIRECTION {
	UP = 1,
	DOWN = -1
}

func _ready():
	if !Engine.is_editor_hint():
		current_cursor_id = cursors.size()
		iterate_actions_cursor(UI_ACTIONS_DIRECTION.UP)
	
func _process(delta):
	$mouse_position.rect_global_position = get_global_mouse_position()


func iterate_actions_cursor(direction: int):
	current_cursor_id += direction
	if current_cursor_id > cursors.size() - 1:
		current_cursor_id = 0
	elif current_cursor_id < 0:
		current_cursor_id = cursors.size() - 1
		
	Input.set_custom_mouse_cursor(cursors[current_cursor_id].texture)
	escoria.action_manager.set_current_action(cursors[current_cursor_id].name)
	if $mouse_position/tool.texture != null:
		clear_tool_texture()

func set_by_name(name: String) -> void:
	for i in cursors.size():
		if cursors[i].name == name:
			current_cursor_id = i
			break
		
	Input.set_custom_mouse_cursor(cursors[current_cursor_id].texture)
	escoria.action_manager.set_current_action(cursors[current_cursor_id].name)

func set_tool_texture(texture: Texture):
	set_process(true)
	$mouse_position/tool.texture = texture

func clear_tool_texture():
	$mouse_position/tool.texture = null
	set_process(false)
