# A simple node extending Position2D with a global ID so that it can be
# referenced in ESC Scripts. Movement-based commands like `walk_to_pos` will
# automatically use an `ESCLocation` that is a child of the destination node.
# Commands like `turn_to`--which are not movement-based--will ignore child
# `ESCLocation`s and refer to the parent node.
extends Position2D
class_name ESCLocation, "res://addons/escoria-core/design/esc_location.svg"


# The global ID of this item
export(String) var global_id

# If true, this ESCLocation is considered as a player start location
export(bool) var is_start_location = false

# If true, player orients towards 'interaction_direction' as
# player character arrives.
export(bool) var player_orients_on_arrival = true

# Let the player turn to this direction when the player arrives
# at the item
export(int) var interaction_direction


# Used by "is" keyword to check whether a node's class_name
# is the same as p_classname.
#
# ## Parameters
#
# p_classname: String class to compare against
func is_class(p_classname: String) -> bool:
	return p_classname == "ESCLocation"


# Ready function
func _ready():
	if not self.global_id.empty():
		escoria.object_manager.register_object(
			ESCObject.new(
				self.global_id,
				self
			),
			null,
			true
		)
