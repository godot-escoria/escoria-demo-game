# Simple pair container to store a room's identifying information for use in
# the object manager.
extends Reference
class_name ESCRoomObjectsKey


var room_global_id: String = ""
var room_instance_id: int = -1


func is_valid():
	return not room_global_id.empty() and room_instance_id > -1
