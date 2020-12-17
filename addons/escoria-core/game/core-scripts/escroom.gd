extends Node2D
class_name ESCRoom

func get_class():
	return "ESCRoom"

export(String) var global_id = ""
export(String, FILE, "*.esc") var esc_script = ""
export(PackedScene) var player_scene
export(Rect2) var camera_limits = Rect2()
var player
onready var game = $game

func _ready():
	
	if player_scene:
		player = player_scene.instance()
		add_child(player)
		escoria.register_object(player)
		game.get_node("camera").set_target(player)
	
	if has_node("player_start"):
		escoria.register_object($player_start)
	
	if global_id.empty():
		global_id = name
	
