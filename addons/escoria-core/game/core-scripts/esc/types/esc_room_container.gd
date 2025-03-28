## Abstract base class for a container of Escoria entities specific to a room 
## to be stored in and used by the Escoria object manager.
extends RefCounted
class_name ESCRoomContainer


## Designates whether the objects contained in this container are all reserved objects.
var is_reserved: bool = false

## Global ID of the room in which the objects in this container are registered.
var room_global_id: String = ""

## Instance ID of the room in which the objects in this container are registered. 
## This is used to disambiguate in cases where more than one of the same room
## exist in the object manager.
var room_instance_id: int = -1
