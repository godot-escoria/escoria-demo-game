# Base class for item components.
# Item components allow to extend base ESCItem without changing the core class.
extends Node
class_name ESCItemComponent, "res://addons/escoria-core/design/esc_item.svg"

# Custom data from the parent.
var _custom_data: Dictionary 

# Returns the global_id from the parent.
func get_global_id():
    return self.get_parent().global_id

# Returns component type string. Requires an unique type for each item component.
func get_component_type():
    pass

# Custom registration. Optional
func register(custom_data: Dictionary):
    pass
