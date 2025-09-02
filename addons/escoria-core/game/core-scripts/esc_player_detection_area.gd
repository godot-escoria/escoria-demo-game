@tool
@icon("res://addons/escoria-core/design/esc_area.svg")
## ESCPlayerDetectionArea is used to define an area that detects whether the player is within the detection area.
extends Area2D
class_name ESCPlayerDetectionArea

## Signals emitted when the player enters or exits the interaction area.
signal player_entered

## Emitted when the player exits the interaction area.
signal player_exited

func _enter_tree():
	name = "player_interaction_area"

func _ready():
	if not area_entered.is_connected(_on_player_entered_interaction_area):
		area_entered.connect(_on_player_entered_interaction_area)
	if not area_exited.is_connected(_on_player_exited_interaction_area):
		area_exited.connect(_on_player_exited_interaction_area)

func _on_player_entered_interaction_area(_body: Node):
	if _body is ESCPlayer:
		player_entered.emit()

func _on_player_exited_interaction_area(_body: Node):
	if _body is ESCPlayer:
		player_exited.emit()
