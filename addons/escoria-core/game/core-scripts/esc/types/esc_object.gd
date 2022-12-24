extends Reference
# An object handled in Escoria
class_name ESCObject


# Default object state
const STATE_DEFAULT: String = "default"


# The global id of the object
var global_id: String

# Whether the object is active (visible to the player)
var active: bool = true setget _set_active, is_active

# Whether the object is interactive (clickable by the player)
var interactive: bool = true setget _set_interactive, _get_interactive

# The state of the object. If the object has a respective animation,
# it will be played
var state: String = STATE_DEFAULT setget set_state, get_state

# The events registered with the object
var events: Dictionary = {}

# The node in the scene. Can be an ESCItem or an ESCCamera
var node: Node


func _init(p_global_id: String, p_node: Node):
	global_id = p_global_id
	node = p_node


# Get the current state
#
# *Returns* the current state
func get_state() -> String:
	return state


# Set the state and start a possible animation
#
# #### Parameters
#
# - p_state: State to set
# - immediate: If true, skip directly to the end
func set_state(p_state: String, immediate: bool = false):
	state = p_state

	if node.has_method("get_animation_player"):
		var animation_node: ESCAnimationPlayer = node.get_animation_player()

		if animation_node != null and animation_node.is_valid():
			animation_node.stop()
			var actual_animator
			if animation_node.has_animation(p_state):
				if immediate:
					escoria.logger.debug(
						self,
						"State \"%s\" set. Matching immediate animation executing."
								% p_state
					)
					animation_node.seek_end(p_state)
				else:
					escoria.logger.debug(
						self,
						"State \"%s\" set. Matching non-immediate animation executing."
								% p_state
					)
					animation_node.play(p_state)
			else:
				escoria.logger.debug(
					self,
					"State \"%s\" set. No matching animation found."
							% p_state
				)


# Set the active value, thus hiding or showing the object
#
# #### Parameters
#
# - value: Value to set
func _set_active(value: bool):
	active = value
	self.node.visible = value


# Returns whether the object is active
#
# *Returns* true iff the object is active
func is_active() -> bool:
	return active


# Get the interactive value from the node
#
# **Returns** Whether the node is interactive or not
func _get_interactive() -> bool:
	if is_instance_valid(self.node) and "is_interactive" in self.node:
		return self.node.is_interactive
	else:
		return true


# Set the interactive value in the node
#
# #### Parameters
# - value: Whether the object is interactive or not
func _set_interactive(value: bool):
	if "is_interactive" in self.node:
		self.node.is_interactive = value
		if not value:
			escoria.game_scene.clear_tooltip()
			escoria.inputs_manager.on_item_non_interactive(self.node)


# Return the data of the object to be inserted in a savegame file.
#
# **Returns**
# A dictionary containing the data to be saved for this object.
func get_save_data() -> Dictionary:
	var save_data: Dictionary = {}

	if self.global_id == "player" and not is_instance_valid(self.node):
		return save_data

	save_data["active"] = self.active
	save_data["interactive"] = self.interactive
	save_data["state"] = self.state

	if is_instance_valid(self.node):
		if self.node.get("is_movable") and self.node.is_movable:
			save_data["global_transform"] = self.node.global_transform
			save_data["last_deg"] = wrapi(self.node._movable._get_angle() - 90 + 1, 0, 360)
			save_data["last_dir"] = self.node._movable.last_dir
		if self.node.has_method("get_custom_data"):
			save_data["custom_data"] = self.node.get_custom_data()

	if self.global_id in ["_music", "_sound"] and self.node.get("state"):
		save_data["state"] = self.node.get("state")
		save_data["playback_position"] = self.node.get_playback_position()

	if self.global_id == "_camera":
		save_data["target"] = self.node.get("_follow_target").global_id

	return save_data
