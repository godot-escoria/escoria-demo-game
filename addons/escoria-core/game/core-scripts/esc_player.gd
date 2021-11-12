# A playable character
tool
extends ESCItem
class_name ESCPlayer, "res://addons/escoria-core/design/esc_player.svg"




# Wether the player can be selected like an item
export(bool) var selectable = false


# A player is always movable
func _init():
	is_movable = true


# Ready function
func _ready():
	if selectable:
		._ready()
	else:
		tooltip_name = ""
		disconnect("input_event", self, "manage_input")
