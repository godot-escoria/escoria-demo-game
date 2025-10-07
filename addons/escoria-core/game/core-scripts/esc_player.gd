@tool
@icon("res://addons/escoria-core/design/esc_player.svg")
## An Escoria playable character.
extends ESCItem
class_name ESCPlayer


## Whether the player can be hovered over and actions performed on like an item.
## This allows the user to perform actions or use items on the player character.
@export var selectable: bool = false

## Constructor method.
func _init():
	# A player is always movable
	is_movable = true
	_force_registration = true


## Ready method. 
func _ready():
	super()
