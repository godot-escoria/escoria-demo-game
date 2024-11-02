# Container for ESCObjects stored in the object manager.
extends RefCounted
class_name ESCRoomContainer


# Designated whether 'objects' is the container for all reserved objects.
var is_reserved: bool = false

# Global ID of the room to which the objects in 'objects' are registered.
var room_global_id: String = ""

# Instance ID of the room to which the objects in 'objects' are registered.
# This is used to disambiguate in cases where more than one of the same room
# exist in the object manager.
var room_instance_id: int = -1
