tool
extends Node2D
class_name ESCRoom

func get_class():
	return "ESCRoom"

export(String) var global_id = ""
export(String, FILE, "*.esc") var esc_script = ""
export(PackedScene) var player_scene
export(Array, Rect2) var camera_limits : Array = [Rect2()] setget set_camera_limits
var player
onready var game = $game

### EDITOR TOOLS ###
enum EDITOR_ROOM_DEBUG_DISPLAY {
	NONE, 
	CAMERA_LIMITS
}
export(EDITOR_ROOM_DEBUG_DISPLAY) var editor_debug_mode = EDITOR_ROOM_DEBUG_DISPLAY.NONE setget set_editor_debug_mode
onready var camera_limits_colors : Array = [
	ColorN("red"), ColorN("blue"), ColorN("green")
]
### END EDITOR TOOLS ###

func _enter_tree():
	randomize()


func _ready():
	if camera_limits.empty():
		camera_limits.push_back(Rect2())
	if camera_limits.size() == 1 and camera_limits[0].has_no_area():
		camera_limits[0] = Rect2(0, 0, $background.rect_size.x, $background.rect_size.y)
		
	if Engine.is_editor_hint():
		return
	
	if player_scene:
		player = player_scene.instance()
		add_child(player)
		escoria.object_manager.register_object(
			ESCObject.new(
				player.global_id,
				player
			),
			true
		)
		game.get_node("camera").set_target(player)
	
	if has_node("player_start"):
		escoria.object_manager.register_object(
			ESCObject.new(
				$player_start.name,
				$player_start
			),
			true
		)
	
	if global_id.empty():
		global_id = name
	
func _draw():
	if !Engine.is_editor_hint():
		return
	if editor_debug_mode == EDITOR_ROOM_DEBUG_DISPLAY.NONE:
		return
	
	# If there are more camera limits than colors defined for them, add more.
	if camera_limits.size() > camera_limits_colors.size():
		for i in camera_limits.size() - camera_limits_colors.size():
			camera_limits_colors.push_back(Color(randf(), randf(), randf(), 1.0))
	
	# Draw lines for camera limits
	for i in camera_limits.size():
		draw_rect(camera_limits[i], camera_limits_colors[i], false, 10.0)
		var default_font = Control.new().get_font("font")
		
		draw_string(default_font, Vector2(camera_limits[i].position.x + 30, 
			camera_limits[i].position.y + 30), str(i), camera_limits_colors[i])

	return

func set_camera_limits(p_camera_limits : Array) -> void:
	camera_limits = p_camera_limits
	update()

func set_editor_debug_mode(p_editor_debug_mode : int) -> void:
	editor_debug_mode = p_editor_debug_mode
	update()
