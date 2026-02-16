extends Area2D

@export var speed = 400 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.

@onready var _change_scene: ChangeSceneCommand = ChangeSceneCommand.new()
const next_scene_path: String = "res://game/rooms/room01/room01.tscn"

func _ready():
	screen_size = get_viewport_rect().size


func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if position.x > 800:
		_change_scene.run([next_scene_path, false])
		queue_free()
