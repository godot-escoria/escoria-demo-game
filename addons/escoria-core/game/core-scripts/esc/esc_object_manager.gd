# A manager for ESC objects
extends Resource
class_name ESCObjectManager


const CAMERA = "_camera"
const MUSIC = "_music"
const SOUND = "_sound"
const SPEECH = "_speech"

const RESERVED_OBJECTS = [
	MUSIC,
	SOUND,
	SPEECH,
]


# The array of registered objects (organized by room, so each entry is a structure
# representing a room and its registered objects). This also includes one
# "room" for reserved objects; that is, we use one entry of the array to
# hold all reserved objects. This entry can be identified by the "is_reserved"
# property being set to true.
#
# "Reserved objects" are those which are named in the RESERVED_OBJECTS const
# array and include objects that are used internally by Escoria in every room,
# e.g. a music player, a sound player, a speech player, the main camera.
#
# In almost all cases, the reserved objects' entry doesn't need updating once
# created.
#
# Example structure:
#
#	[
#		{
#			is_reserved: true,	# Indicates this is the "reserved objects" entry
#			room: "",
#			room_instance_id: "",
#			objects:
#				{
#					"_camera": camera
#				},
#		},
#		{
#			is_reserved: false,	# Indicates this an entry for a room's objectss
#			room_global_id: "<room_global_id>",
#			room_instance_id: "<room_object_instance_id>",
#			objects:
#				{
#					"obj1": val1,
#					"obj2": val2
#				}
#		}
#	]
var room_objects: Array = []

# Array containing the encountered terrains so they can be properly saved in savegames
var room_terrains: Array = []

# We also store the current room's ids for retrieving the right objects.
var current_room_key: ESCRoomObjectsKey

# To avoid having to look this up all the time, we hold a reference.
var reserved_objects_container: ESCRoomObjects


func _init() -> void:
	reserved_objects_container = ESCRoomObjects.new()
	reserved_objects_container.is_reserved = true
	reserved_objects_container.objects = {}
	room_objects.push_back(reserved_objects_container)

	current_room_key = ESCRoomObjectsKey.new()


# Updates which object manager room is to be treated as the currently active one.
#
# #### Parameters
#
# - room: Room to register the object with in the object manager
func set_current_room(room: ESCRoom) -> void:
	if room == null:
		escoria.logger.error(
			self,
			"Unable to set current room: No room was specified.\n" +
			"Please pass in a valid ESCRoom as an argument to the method."
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

	if object.global_id.is_empty():
		object.global_id = str(object.node.get_path()).split("/root/", false)[0]
		object.node.global_id = object.global_id
		escoria.logger.warn(
			self,
			"Registering ESCObject %s with empty global_id." % object.node.name +
			"Using node's full path as global_id: %s"
						% object.node.global_id
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
	if room == null or room.global_id.is_empty():
		# We duplicate the key so as to not hold a reference when current_room_key
		# changes.
		if current_room_key.room_global_id.is_empty():
			escoria.logger.error(
				self,
				"The current room has no Global ID.\n" +
				"Please set the ESCRoom's Global ID property."
			)
		room_key.room_global_id = current_room_key.room_global_id
		room_key.room_instance_id = current_room_key.room_instance_id

		if not room_key.is_valid():
			# This condition should very likely never happen.
			escoria.logger.error(
				self,
				"No room was specified to register object with, and no current room is properly set.\n" +
				"Please either pass in a valid ESCRoom to this method, or " + \
					"call set_current_room() with a valid ESCRoom first."
			)
	else:
		room_key.room_global_id = room.global_id
		room_key.room_instance_id = room.get_instance_id()

	if not force and _object_exists_in_room(object, room_key) \
			and _object_state_in_room_is_default(object, room_key):
		escoria.logger.warn(
			self,
			"Object with global id '%s' in room %s already registered from node path %s."
			% [
				object.global_id,
				room_key.room_global_id,
				get_object(object.global_id, room).node.get_path()
			]
		)
		return
	# Object exists in room, set it to is last state (if different from
	# "default")
	elif object.node is ESCItem and _object_exists_in_room(object, room_key):
		# Object is already known, set its state to last known state
		object.set_state(get_object(object.global_id).state)

	# If the object is already connected, disconnect it for the case of
	# forcing the registration, since we don't know if this object will be
	# overwritten ("forced") in the future and, if it is, if it's set to
	# auto-unregister or not. In most cases, objects are set to auto unregister.
	if object.node.tree_exited.is_connected(unregister_object):
		object.node.tree_exited.disconnect(unregister_object)

	if force:
		# If this ID already exists and we're about to overwrite it, do the
		# safe thing and unregister the old object first
		unregister_object_by_global_id(object.global_id, room_key)

	if auto_unregister:
		object.node.tree_exited.connect(unregister_object.bind(object, room_key))

	if "is_interactive" in object.node and object.node.is_interactive:
		object.interactive = true

	if "esc_script" in object.node and not object.node.esc_script.is_empty():
		var script = escoria.esc_compiler.load_esc_file(
			object.node.esc_script
		)
		object.events = script.events

	var objects: Dictionary = _get_room_objects_objects(room_key)
	objects[object.global_id] = object

	# If object state is not STATE_DEFAULT, save it in manager's object states
	if object.state != ESCObject.STATE_DEFAULT:
		if get_object(object.global_id) == null:
			escoria.logger.error(
				self,
				"Object with global id %s in room (%s, %s) not found in Object Manager."
				% [
					object.global_id,
					room_key.room_global_id,
					room_key.room_instance_id
				]
			)
		else:
			get_object(object.global_id).state = object.state

	# If this is the first object for the room, that means we have a brand new
	# room and it needs to be setup and tracked.
	if objects.size() == 1:
		var room_container: ESCRoomObjects = ESCRoomObjects.new()
		room_container.room_global_id = room_key.room_global_id
		room_container.room_instance_id = room_key.room_instance_id
		room_container.is_reserved = false
		room_container.objects = objects
		room_objects.push_back(room_container)


# Register the terrain in the manager
#
# #### Parameters
#
# - object: Object contianing the terrain to register
# - room: Room to register the object with in the object manager
func register_terrain(object: ESCObject, room: ESCRoom = null) -> void:
	var room_key: ESCRoomObjectsKey = ESCRoomObjectsKey.new()

	# If a room was passed in, then we're going to register the object with it;
	# otherwise, we register the object with the "current room".
	if not is_instance_valid(room) or room.global_id.is_empty():
		# We duplicate the key so as to not hold a reference when current_room_key
		# changes.
		room_key.room_global_id = current_room_key.room_global_id
		room_key.room_instance_id = current_room_key.room_instance_id

		if not room_key.is_valid():
			# This condition should very likely never happen.
			escoria.logger.error(
				self,
				"No room was specified to register terrain with, and no current room is properly set.\n" +
				"Please either pass in a valid ESCRoom to this method, or " + \
					"call set_current_room() with a valid ESCRoom first."
			)
	else:
		room_key.room_global_id = room.global_id
		room_key.room_instance_id = room.get_instance_id()

	var terrains: Dictionary = _get_room_terrain_navpolys(room_key)
	if object.node is NavigationRegion2D:
		terrains[object.global_id] = object
		if terrains[object.global_id].node.enabled:
			terrains[object.global_id].state = "enabled"

	if terrains.size() == 1:
		var room_container: ESCRoomTerrains = ESCRoomTerrains.new()
		room_container.room_global_id = room_key.room_global_id
		room_container.room_instance_id = room_key.room_instance_id
		room_container.terrains = terrains
		if room_terrains.has(room_container):
			room_terrains.erase(room_container)
		room_terrains.push_back(room_container)


# Check whether an object was registered
#
# #### Parameters
#
# - global_id: Global ID of object
# - room: ESCRoom instance the object is registered with.
# ***Returns*** Whether the object exists in the object registry
func has(global_id: String, room: ESCRoom = null) -> bool:
	if global_id in RESERVED_OBJECTS:
		if reserved_objects_container == null:
			return false

		return reserved_objects_container.objects.has(global_id)

	var room_key: ESCRoomObjectsKey

	if room == null:
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
# ***Returns*** The retrieved object, or null if not found
func get_object(global_id: String, room: ESCRoom = null) -> ESCObject:
	if global_id in RESERVED_OBJECTS:
		if reserved_objects_container.objects.has(global_id):
			return reserved_objects_container.objects[global_id]
		else:
			escoria.logger.warn(
				self,
				"Reserved object with global id %s not found in object manager!"
					% global_id
			)
			return null

	var room_key: ESCRoomObjectsKey

	if room == null:
		room_key = current_room_key
	else:
		room_key = ESCRoomObjectsKey.new()
		room_key.room_global_id = room.global_id
		room_key.room_instance_id = room.get_instance_id()

	if not _room_exists(room_key):
		escoria.logger.warn(
			self,
			"Specified room is empty/not found.\n" +
			"Object with global id %s in room instance (%s, %s) not found."
			% [global_id, room_key.room_global_id, room_key.room_instance_id]
		)
		return null

	var objects: Dictionary = _get_room_objects_objects(room_key)

	if objects.has(global_id):
		return objects[global_id]
	else:
		escoria.logger.warn(
			self,
			"Object with global id %s in room instance (%s, %s) not found. This can be safely ignored if a room was being searched for."
			% [global_id, room_key.room_global_id, room_key.room_instance_id]
		)
		if escoria.inventory_manager.inventory_has(global_id):
			# item is in the inventory and may be registered to a different room
			for single_room in room_objects:
				# these are arrays of the objects still registered for each room
				if single_room.objects.has(global_id):
					escoria.logger.info(
						self,
						"Object with global id %s found in room instance (%s, %s) through the inventory."
						% [global_id, room_key.room_global_id, room_key.room_instance_id]
					)
					return single_room.objects[global_id]
		return null


# Remove an object from the registry
#
# #### Parameters
#
# - object: The object to unregister
# - room_key: The room under which the object should be unregistered.
func unregister_object(object: ESCObject, room_key: ESCRoomObjectsKey) -> void:
	if not _object_exists_in_room(object, room_key):
		# Report this as a warning and not an error since this method may be
		# called as part of an objectd's forced registration and the object not
		# yet being managed.
		escoria.logger.debug(
			self,
			"Unable to unregister object. " +
			"Object with global ID %s room (%s, %s) not found. If this was "
			% [
				"?" if object == null else object.global_id,
				room_key.room_global_id,
				room_key.room_instance_id
			] +
			"part of a 'forced' registration, ignore this warning."
		)

		return

	var room_objects = _get_room_objects_objects(room_key)

	if not escoria.is_quitting and escoria.inventory_manager.inventory_has(object.global_id):
		# Re-instance the node if it is an item present in inventory; that is,
		# re-register it with the new current room.
		if object.node != null:
			object.node = object.node.duplicate()
			register_object(object, null, true)

	if object.state == ESCObject.STATE_DEFAULT:
		room_objects.erase(object.global_id)

	# If this room is truly empty, it's time to do away with it.
	if room_objects.size() == 0:
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
	p_savegame.objects = {}

	for room_obj in room_objects:
		if room_obj.room_global_id.is_empty():
			continue

		var room_objects_dict = {}
		for obj_id in room_obj.objects:
			var obj: ESCObject = room_obj.objects[obj_id]
			var obj_json_to_save: Dictionary = obj.get_save_data()
			if not obj_json_to_save.is_empty():
				room_objects_dict[obj_id] = obj_json_to_save

		p_savegame.objects[room_obj.room_global_id] = room_objects_dict

	# Add in reserved objects (music, speech, sound), too.
	var reserved_objects: Dictionary = reserved_objects_container.objects
	for obj_global_id in reserved_objects:
		if not reserved_objects[obj_global_id] is ESCObject:
			continue
		p_savegame.objects[obj_global_id] = reserved_objects[obj_global_id].get_save_data()

	# Add ENABLED terrain navigationpolygons in, too.
	p_savegame.terrain_navpolys = {}

	for room_terrain_container in room_terrains:
		if room_terrain_container.room_global_id == current_room_key.room_global_id:
			for terrain_name in room_terrain_container.terrains:
				var terrain_escobj = room_terrain_container.terrains[terrain_name]
				if terrain_escobj.node.enabled:
					p_savegame.terrain_navpolys[room_terrain_container.room_global_id] = {}
					p_savegame.terrain_navpolys[room_terrain_container.room_global_id][terrain_name] = \
							terrain_escobj.node.enabled


# Returns the current room's starting location. If more than one exists, the
# first one encountered is returned.
func get_start_location() -> ESCLocation:
	if _room_exists(current_room_key):
		for object in _get_room_objects_objects(current_room_key).values():
			if is_instance_valid(object.node):
				var loc := object.node as ESCLocation
				if loc and loc.is_start_location:
					return loc

	escoria.logger.warn(
		self,
		"Room has no ESCLocation node with 'is_start_location' enabled. " +
		"Player will be set at position (0,0)."
	)
	return null


# Determines whether 'container' represents the current room the player is in.
#
# #### Parameters
#
# - container: The entry in the object manager array being checked.
# **Returns** True iff container represents the the current room the player is in.
func _is_current_room(container: ESCRoomObjects) -> bool:
	return _compare_container_to_key(container, current_room_key)


# Determines whether 'container' represents the room specified.
#
# #### Parameters
#
# - container: The entry in the object manager array being checked.
# - room_key: The key representing the desired room in the object manager array.
# **Returns** True iff container represents the object manager entry specified
# by room_key.
func _compare_container_to_key(container: ESCRoomContainer, room_key: ESCRoomObjectsKey) -> bool:
	return container.room_global_id == room_key.room_global_id


# Checks whether an entry in the object manager array corresponds to the passed in
# room key.
#
# #### Parameters
#
# - room_key: The key representing the desired room in the object manager array.
# **Returns** True iff an entry in the object manager array corresponds to room_key.
func _room_exists(room_key: ESCRoomObjectsKey) -> bool:
	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key):
			return true

	return false


# Checks whether the specified object exists in the specified object manager entry.
#
# #### Parameters
#
# - object: The object to check for existence.
# - room_key: The key representing the desired room in the object manager array.
# **Returns** True iff object exists in the object manager entry specified by room_key.
func _object_exists_in_room(object: ESCObject, room_key: ESCRoomObjectsKey) -> bool:
	if object == null:
		escoria.logger.warn(
			self,
			"Cannot check room for \"null\" objects."
		)

		return false

	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key) \
				and room_container.objects.has(object.global_id):
			return true

	return false


# Checks whether the specified object's state is "default" in the specified object manager entry.
#
# #### Parameters
#
# - object: The object to check for existence.
# - room_key: The key representing the desired room in the object manager array.
# **Returns** True if object's state is "default" in the object manager entry specified by room_key.
func _object_state_in_room_is_default(object: ESCObject, room_key: ESCRoomObjectsKey) -> bool:
	if object == null:
		escoria.logger.warn(
			self,
			"Cannot check room for \"null\" objects."
		)

		return false

	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key) \
				and room_container.objects.has(object.global_id) \
				and room_container.objects.get(object.global_id).state == ESCObject.STATE_DEFAULT:
			return true

	return false


# Returns the objects currently being managed in the object manager entry specified
# by the specified room key.
#
# #### Parameters
#
# - room_key: The key representing the desired room in the object manager array.
# **Returns** A reference to the dictionary of the entry's objects, or an empty
# dictionary otherwise.
func _get_room_objects_objects(room_key: ESCRoomObjectsKey) -> Dictionary:
	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key):
			return room_container.objects

	return {}


func _get_room_terrain_navpolys(room_key: ESCRoomObjectsKey) -> Dictionary:
	for room_container in room_terrains:
		if _compare_container_to_key(room_container, room_key):
			return room_container.terrains

	return {}


# Completely removes the entry in the object manager array specified by the room
# key.
#
# #### Parameters
#
# - room_key: The key representing the desired room in the object manager array.
func _erase_room(room_key: ESCRoomObjectsKey) -> void:
	for room_container in room_objects:
		if _compare_container_to_key(room_container, room_key):
			room_objects.erase(room_container)
			return
