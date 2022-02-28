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

# Separator to use for each room's entry in the objects dictionary.
const SEPARATOR = "!!!!"

# Dictionary key for reserved objects.
const RESERVED_KEY = "reserved"

# The hash of registered objects (organized by room, with the object's global id 
# serving as the object's key).
#
# Example structure:
#
#	{ 
#		"reserved":
#			{
#				"_camera": camera
#			},
#		"room1!!!!<instance_id>":
#			{
#				"obj1": val1,
#				"obj2": val2
#			}	
#	}
#
# Note that the "reserved" entry cannot be altered or otherwise changed and
# that it belongs to no specific room.
var objects: Dictionary = {RESERVED_KEY: {}}

# We also store the current room's complete key in objects for convenience.
var current_room_key: String = ""


# Use this to track the room we just exited for the purpose o
var prev_room_key: String = ""

# Make active objects in current room visible
func _process(_delta):
	for object in objects[current_room_key]:
		if (object as ESCObject).node:
			(object as ESCObject).node.visible = (object as ESCObject).active

	for object in objects[RESERVED_KEY]:
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

	current_room_key = _make_room_key(room)


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
		objects[RESERVED_KEY][object.global_id] = object
		return

	var room_key: String = ""
	
	# If a room was passed in, then we're going to register the object with it;
	# otherwise, we register the object with the "current room".
	if room == null or room.global_id.empty():
		room_key = current_room_key
		
		if room_key.empty():
			escoria.logger.report_errors(
				"ESCObjectManager:register_object()",
				[
					"No room was specified to register object with, and no current room is properly set."
				]
			)
	else:
		room_key = _make_room_key(room)

	if objects.has(room_key) and objects[room_key].has(object.global_id):
		if force:
			# If this ID already exists and we're about to overwrite it, do the 
			# safe thing and unregister the old object first
			unregister_object_by_global_id(object.global_id, room_key)
		else:
			escoria.logger.report_errors(
				"ESCObjectManager:register_object()",
				[
					"Object with global id %s in room %s already registered" % 
							object.global_id,
							room_key
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
	
	if not objects.has(room_key):
		objects[room_key] = {}

	objects[room_key][object.global_id] = object


# Check whether an object was registered
#
# #### Parameters
#
# - global_id: Global ID of object
# - room: ESCRoom instance the object is registered with.
# **Returns** Whether the object exists in the object registry
func has(global_id: String, room: ESCRoom = null) -> bool:
	if global_id in RESERVED_OBJECTS:
		if objects[RESERVED_KEY] == null:
			return false

		return objects[RESERVED_KEY].has(global_id)
	
	var room_key: String = ""
	
	if room == null:
		escoria.logger.trace("ESCObjectManager.has(): No room specified." \
			+ " Defaulting to current room."
		)

		room_key = current_room_key
	else:
		room_key = _make_room_key(room)

	if objects[room_key] == null:
		return false

	return objects[room_key].has(global_id)


# Get the object from the object registry
#
# #### Parameters
#
# - global_id: The global id of the object to retrieve
# - room: ESCRoom instance the object is registered with.
# **Returns** The retrieved object, or null if not found 
func get_object(global_id: String, room: ESCRoom = null) -> ESCObject:
	if global_id in RESERVED_OBJECTS:
		if objects[RESERVED_KEY].has(global_id):
			return objects[RESERVED_KEY][global_id]
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

	var room_key: String = ""

	if room == null:
		escoria.logger.trace("ESCObjectManager.has(): No room specified." \
			+ " Defaulting to current room."
		)

		room_key = current_room_key
	else:
		room_key = _make_room_key(room)

	if objects[room_key] == null:
		escoria.logger.report_warnings(
			"ESCObjectManager:get_object()",
			[
				"Specified room empty/not found.",
				"Object with global id %s in room instance %s not found" 
				% global_id, room_key
			]
		)
		return null

	if objects[room_key].has(global_id):
		return objects[room_key][global_id]
	else:
		escoria.logger.report_warnings(
			"ESCObjectManager:get_object()",
			[
				"Invalid object retrieved.",
				"Object with global id %s in room instance %s not found" 
				% global_id, room_key
			]
		)
		return null


# Remove an object from the registry
#
# #### Parameters
#
# - object: The object to unregister
# - room_key: The room under which the object should be unregistered.
func unregister_object(object: ESCObject, room_key: String) -> void:
	if objects[room_key] == null:
		escoria.logger.report_errors(
			"ESCObjectManager:unregister_object()",
			[
				"Unable to unregister object.",
				"Room with key %s not found." % room_key
			]
		)

	if not escoria.inventory_manager.inventory_has(object.global_id):
		objects[room_key].erase(object.global_id)
	else:
		# Re-instance the node if it is an item present in inventory.
		objects[room_key][object.global_id].node = \
			objects[room_key][object.global_id].node.duplicate()

	# If this room is truly empty, it's time to do away with it.
	if objects[room_key].size() == 0:
		objects.erase(room_key)


# Remove an object from the registry by global_id
#
# #### Parameters
#
# - global_id: The global_id of the object to unregister
# - room_key: The room under which the object should be unregistered.
func unregister_object_by_global_id(global_id: String, room_key: String) -> void:
	unregister_object(ESCObject.new(global_id, null), room_key)


# Insert data to save into savegame. For now, we only save the current room's
# objects.
#
# #### Parameters
#
# - p_savegame: The savegame resource
func save_game(p_savegame: ESCSaveGame) -> void:
	if current_room_key.empty() or objects[current_room_key] == null:
		escoria.logger.report_errors(
			"ESCObjectManager:save_game()",
			[
				"No current room specified or found."
			]
		)
		
	p_savegame.objects = {}
	for obj_global_id in objects[current_room_key]:
		if !objects[current_room_key][obj_global_id] is ESCObject:
			continue
		p_savegame.objects[current_room_key][obj_global_id] = \
			objects[current_room_key][obj_global_id].get_save_data()


func get_start_location() -> ESCLocation:
	if objects.has(current_room_key):
		for object in objects[current_room_key].values():
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


# Utility function to fashion a room key for the object manager.
func _make_room_key(room: ESCRoom) -> String:
	return room.global_id + SEPARATOR + str(room.get_instance_id())
