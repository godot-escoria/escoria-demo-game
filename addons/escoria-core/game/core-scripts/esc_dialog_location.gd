# A simple node extending Position2D with a global ID so that it can be
# referenced in ESC Scripts. Movement-based commands like `walk_to_pos` will
# automatically use an `ESCLocation` that is a child of the destination node.
# Commands like `turn_to`--which are not movement-based--will ignore child
# `ESCLocation`s and refer to the parent node.
tool
extends ESCLocation
class_name ESCDialogLocation, "res://addons/escoria-core/design/esc_location.svg"

# p_classname: String class to compare against
func is_class(p_classname: String) -> bool:
	return p_classname == "ESCDialogLocation"
