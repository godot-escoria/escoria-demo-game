# Simple pair container to store a room's identifying information for use in
# the object manager.
extends Reference
class_name ESCRoomObjectsKey


# Contains the global_id of the room being represented by this key.
var room_global_id: String = ""

# Contains the instance ID of the room being represented by this key.
var room_instance_id: int = -1


# Checks whether this key is valid and represents an actual room.
#
# **Returns** true iff the key has a valid global_id and room instance ID.
func is_valid() -> bool:
	return not room_global_id.empty() and room_instance_id > -1
