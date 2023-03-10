# A simple node extending Position2D with a global ID so that it can be
# referenced in ESC Scripts. Movement-based commands like `walk_to_pos` will
# automatically use an `ESCLocation` that is a child of the destination node.
# Commands like `turn_to`--which are not movement-based--will ignore child
# `ESCLocation`s and refer to the parent node.
tool
extends Position2D
class_name ESCLocation, "res://addons/escoria-core/design/esc_location.svg"


signal is_start_location_set


const MULTIPLE_START_LOCATIONS_WARNING = \
	"Only 1 ESCLocation should have is_start_location set to true in an ESCRoom"


# The global ID of this item
export(String) var global_id

# If true, this ESCLocation is considered as a player start location
export(bool) var is_start_location = false setget set_is_start_location

# If true, player orients towards 'interaction_direction' as
# player character arrives.
export(bool) var player_orients_on_arrival = true

# Let the player turn to this direction when the player arrives
# at the item
export(int) var interaction_direction


var _multiple_start_locations_exist: bool = false setget set_multiple_locations_exist


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
	if not Engine.is_editor_hint():
		if not self.global_id.empty():
			escoria.object_manager.register_object(
				ESCObject.new(
					self.global_id,
					self
				)
			)


func _exit_tree():
	if Engine.is_editor_hint():
		if is_start_location:
			emit_signal("is_start_location_set", self)


func _get_configuration_warning():
	if _multiple_start_locations_exist:
		return MULTIPLE_START_LOCATIONS_WARNING

	return ""


func set_multiple_locations_exist(value: bool) -> void:
	_multiple_start_locations_exist = value
	update_configuration_warning()


func set_is_start_location(value: bool) -> void:
	is_start_location = value

	if Engine.is_editor_hint() and is_instance_valid(get_owner()):
		emit_signal("is_start_location_set")
