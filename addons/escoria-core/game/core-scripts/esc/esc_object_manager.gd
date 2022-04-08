# A manager for ESC objects
extends Node
class_name ESCObjectManager


const CAMERA = "_camera"
const MUSIC = "_music"
const SOUND = "_sound"
const SPEECH = "_speech"

const RESERVED_OBJECTS = [
	MUSIC,
	SOUND,
	SPEECH,
	CAMERA
]

# The array of registered objects (organized by room, incl. one "room" for 
# reserved objects).
#
# Example structure:
#
#	[
#		{
#			is_reserved: true,
#			room: "",
#			room_instance_id: "",
#			objects:
#				{
#					"_camera": camera
#				},
#		},
#		{
#			is_reserved: false,
#			room_global_id: "<room_global_id>",
#			room_instance_id: "<room_object_instance_id>",
#			objects:
#				{
#					"obj1": val1,
#					"obj2": val2
#				}
#		}
#	]
#
# Note that the "is_reserved" entry cannot be altered or otherwise changed and
# that it belongs to no specific room.
var room_objects: Array = []

# We also store the current room's ids for retrieving the right objects.
var current_room_key: ESCRoomObjectsKey

# To avoid having to look this up all the time, we hold a reference.
var reserved_objects_container: ESCRoomObjects

# Use this to track the room we just exited for the purpose o
var prev_room_key: String = ""


func _init() -> void:
	reserved_objects_container = ESCRoomObjects.new()
	reserved_objects_container.is_reserved = true
	reserved_objects_container.objects = {}
	room_objects.push_back(reserved_objects_container)

	current_room_key = ESCRoomObjectsKey.new()


# Make active objects in current room visible
func _process(_delta):
	for room in room_objects:
		if room.is_reserved or _is_current_room(room):
			for object in room.objects:
				if (object as ESCObject).node:
					(object as ESCObject).node.visible = (object as ESCObject).active


# Updates which object manager room is to be treated as the currently active one.
#
# #### Parameters
#
# - room: Room to register the object with in the object manager
func set_current_room(room: ESCRoom) -> void:
	if room == null:
		escoria.logger.report_errors(
			"ESCObjectManager:set_current_room()",
			[
				"Unable to set current room: No valid room specified."
			]
		)

	current_room_key.room_global_id = room.global_id
	current_room_key.room_instance_id = room.get_instance_id()


# Register the object in the manager
#
# #### Parameters
#
# - object: Object to register
# - room: Room to register the object with in the object manager
# - force: Register the object, even if it has already been registered
# - auto_unregister: Automatically unregister object on tree_exited
func register_object(object: ESCObject, room: ESCRoom = null, force: bool = false, \
	auto_unregister: bool = true) -> void:

	if object.global_id.empty():
		object.global_id = str(object.node.get_path()).split("/root/", false)[0]
		object.node.global_id = object.global_id
		escoria.logger.report_warnings(
			"ESCObjectManager:register_object()",
			[
				"Registering object with empty global_id.",
				"Using node's full path as global_id: %s"
						% object.node.global_id
			]
		)

	# If this is a reserved object, let's make sure it's in the right place.
	# Note that we also don't allow it to auto unregister and, as such, we need
	# to make sure we clean these up when the application exits.
	if object.global_id in RESERVED_OBJECTS:
		reserved_objects_container.objects[object.global_id] = object
		return

	var room_key: ESCRoomObjectsKey = ESCRoomObjectsKey.new()
	
	# If a room was passed in, then we're going to register the object with it;
	# otherwise, we register the object with the "current room".
	if room == null or room.global_id.empty():
		# We duplicate the key so as to not hold a reference when current_room_key
		# changes.
		room_key.room_global_id = current_room_key.room_global_id
		room_key.room_instance_id = current_room_key.room_instance_id
		
		if not room_key.is_valid():
			escoria.logger.report_errors(
				"ESCObjectManager:register_object()",
				[
					"No room was specified to register object with, and no current room is properly set."
				]
			)
	else:
		room_key = ESCRoomObjectsKey.new()
		room_key.room_global_id = room.global_id
		room_key.room_instance_id = room.get_instance_id()

	if _object_exists_in_room(object, room_key):
		if force:
			# If this ID already exists and we're about to overwrite it, do the 
			# safe thing and unregister the old object first
			unregister_object_by_global_id(object.global_id, room_key)
		else:
			escoria.logger.report_errors(
				"ESCObjectManager:register_object()",
				[
					"Object with global id %s in room (%s, %s) already registered" % 
						[
							object.global_id,
							room_key.room_global_id,
							room_key.room_instance_id
						]
				]
			)

			return

	# If the object is already connected, disconnect it for the case of
	# forcing the registration,since we don't know if this object will be
	# overwritten ("forced") in the future and, if it is, if it's set to
	# auto-unregister or not. In most cases, objects are set to auto unregister.
	if object.node.is_connected(
		"tree_exited", 
		self, 
		"unregister_object"
	):
		object.node.disconnect(
			"tree_exited",
			self,
			"unregister_object"
		)
	
	if auto_unregister:
		object.node.connect(
			"tree_exited", 
			self, 
			"unregister_object", 
			[object, room_key]
		)
	
	if "is_interactive" in object.node and object.node.is_interactive:
		object.interactive = true
	
	if "esc_script" in object.node and not object.node.esc_script.empty():
		var script = escoria.esc_compiler.load_esc_file(
			object.node.esc_script
		)
		object.events = script.events
	
	var objects: Dictionary = _get_room_objects_objects(room_key)
	objects[object.global_id] = object

	# If this is the first object for the room, that means we have a brand new
	# room and it needs to be setup and tracked.
	if objects.size() == 1:
		var room_container: ESCRoomObjects = ESCRoomObjects.new()
		room_container.room_global_id = room_key.room_global_id
		room_container.room_instance_id = room_key.room_instance_id
		room_container.is_reserved = false
		room_container.objects = objects

		room_objects.push_back(room_container)


# Check whether an object was registered
#
# #### Parameters
#
# - global_id: Global ID of object
# - room: ESCRoom instance the object is registered with.
# **Returns** Whether the object exists in the object registry
func has(global_id: String, room: ESCRoom = null) -> bool:
	if global_id in RESERVED_OBJECTS:
		if reserved_objects_container == null:
			return false

		return reserved_objects_container.objects.has(global_id)

	var room_key: ESCRoomObjectsKey
	
	if room == null:
		escoria.logger.trace("ESCObjectManager.has(): No room specified." \
			+ " Defaulting to current room."
		)

		room_key = current_room_key
	else:
		room_key = ESCRoomObjectsKey.new()
		room_key.room_global_id = room.global_id
		room_key.room_instance_id = room.get_instance_id()
	
	if not _room_exists(room_key):
		return false

	return _object_exists_in_room(ESCObject.new(global_id, null), room_key)


# Get the object from the object registry
#
# #### Parameters
#
# - global_id: The global id of the object to retrieve
# - room: ESCRoom instance the object is registered with.
# **Returns** The retrieved object, or null if not found 
func get_object(global_id: String, room: ESCRoom = null) -> ESCObject:
	if global_id in RESERVED_OBJECTS:
		if reserved_objects_container.objects.has(global_id):
			return reserved_objects_container.objects[global_id]
		else:
			escoria.logger.report_warnings(
				"ESCObjectManager:get_object()",
				[
					"Invalid reserved object retrieved.",
					"Reserved object with global id %s not found" 
						% global_id
				]
			)
			return null

	var room_key: ESCRoomObjectsKey

	if room == null:
		escoria.logger.trace("ESCObjectManager.has(): No room specified." \
			+ " Defaulting to current room."
		)

		room_key = current_room_key
	else:
		room_key.room_global_id = room.global_id
		room_key.room_instance_id = room.get_instance_id()

	if not _room_exists(room_key):
		escoria.logger.report_warnings(
			"ESCObjectManager:get_object()",
			[
				"Specified room empty/not found.",
				"Object with global id %s in room instance (%s, %s) not found" 
				% [global_id, room_key.room_global_id, room_key.room_instance_id]
			]
		)
		return null

	var objects: Dictionary = _get_room_objects_objects(room_key)
	
	if objects.has(global_id):
		return objects[global_id]
	else:
		escoria.logger.report_warnings(
			"ESCObjectManager:get_object()",
			[
				"Invalid object retrieved.",
				"Object with global id %s in room instance (%s, %s) not found" 
				% [global_id, room_key.room_global_id, room_key.room_instance_id]
			]
		)
		return null


# Remove an object from the registry
#
# #### Parameters
#
# - object: The object to unregister
# - room_key: The room under which the object should be unregistered.
func unregister_object(object: ESCObject, room_key: ESCRoomObjectsKey) -> void:
	if not _object_exists_in_room(object, room_key):
		escoria.logger.report_errors(
			"ESCObjectManager:unregister_object()",
			[
				"Unable to unregister object.",
				"Object with global ID %s room (%s, %s) not found." %
				[
					"?" if object == null else object.global_id,
					room_key.room_global_id,
					room_key.room_instance_id
				]
			]
		)

	var objects = _get_room_objects_objects(room_key)

	if not escoria.inventory_manager.inventory_has(object.global_id):
		objects.erase(object.global_id)
	else:
		# Re-instance the node if it is an item present in inventory.
		objects[object.global_id].node = \
			objects[object.global_id].node.duplicate()

	# If this room is truly empty, it's time to do away with it.
	if objects.size() == 0:
		_erase_room(room_key)


# Remove an object from the registry by global_id
#
# #### Parameters
#
# - global_id: The global_id of the object to unregister
# - room_key: The room under which the object should be unregistered.
func unregister_object_by_global_id(global_id: String, room_key: ESCRoomObjectsKey) -> void:
	unregister_object(ESCObject.new(global_id, null), room_key)


# Insert data to save into savegame. For now, we only save the current room's
# objects.
#
# #### Parameters
#
# - p_savegame: The savegame resource
func save_game(p_savegame: ESCSaveGame) -> void:
	if not current_room_key.is_valid() or not _room_exists(current_room_key):
		escoria.logger.report_errors(
			"ESCObjectManager:save_game()",
			[
				"No current room specified or found."
			]
		)
	
	var objects: Dictionary = _get_room_objects_objects(current_room_key)	
	
	p_savegame.objects = {}
	
	for obj_global_id in objects:
		if not objects[obj_global_id] is ESCObject:
			continue
		p_savegame.objects[obj_global_id] = \
			objects[obj_global_id].get_save_data()


func get_start_location() -> ESCLocation:
	if _room_exists(current_room_key):
		for object in _get_room_objects_objects(current_room_key).values():
			if is_instance_valid(object.node) \
					and object.node is ESCLocation \
					and object.node.is_start_location:
				return object

	escoria.logger.report_warnings(
			"ESCObjectManager:get_start_location()",
			[
				"Room has no ESCLocation node with 'is_start_location' enabled.",
				"Player will be set at position (0,0) by default."
			]
		)
	return null


# TODO: Document signatures
#func _is_current_room(container: ESCRoomObjects) -> bool:
func _is_current_room(container) -> bool:
	return _compare_container_to_key(container, current_room_key)


func _compare_container_to_key(container: ESCRoomObjects, room_key: ESCRoomObjectsKey) -> bool:
	return container.room_global_id == room_key.room_global_id \
		and container.room_instance_id == room_key.room_instance_id


func _room_exists(room_key: ESCRoomObjectsKey) -> bool:
	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key):
			return true

	return false


func _object_exists_in_room(object: ESCObject, room_key: ESCRoomObjectsKey) -> bool:
	if object == null:
		escoria.logger.report_warnings(
			"ESCObjectManager:_object_exists_in_room()",
			[
				"Cannot check for null objects."
			]
		)
		
		return false
	
	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key) \
			and room_container.objects.has(object.global_id):
			
			return true

	return false


func _get_room_objects_objects(room_key: ESCRoomObjectsKey) -> Dictionary:
	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key):
			return room_container.objects

	return {}


func _erase_room(room_key: ESCRoomObjectsKey) -> void:
	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key):
			room_objects.erase(room_container)
			return
