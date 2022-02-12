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


# The hash of registered objects (the global id is the key)
var objects: Dictionary = {}


# Make active objects visible
func _process(_delta):
	for object in objects:
		if (object as ESCObject).node:
			(object as ESCObject).node.visible = (object as ESCObject).active


# Register the object in the manager
#
# #### Parameters
#
# - object: Object to register
# - force: Register the object, even if it has already been registered
# - auto_unregister: Automatically unregister object on tree_exited
func register_object(object: ESCObject, force: bool = false, \
	auto_unregister: bool = true) -> void:

	if object.global_id.empty():
		object.global_id = str(object.node.get_path()).split("/root/", false)[0]
		object.node.global_id = object.global_id
		escoria.logger.report_warnings(
			"esc_object_manager.gd:register_object()",
			[
				"Registering object with empty global_id.",
				"Using node's full path as global_id: %s" 
						% object.node.global_id
			]
		)

	if objects.has(object.global_id):
		if force:
			# If this ID already exists and we're about to overwrite it, do the 
			# safe thing and unregister the old object first
			unregister_object_by_global_id(object.global_id)
		else:
			escoria.logger.report_errors(
				"ESCObjectManager.register_object: Object already registered",
				[
					"Object with global id %s already registered" % 
							object.global_id
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
			[object]
		)
	
	if "is_interactive" in object.node and object.node.is_interactive:
		object.interactive = true
	
	if "esc_script" in object.node and not object.node.esc_script.empty():
		var script = escoria.esc_compiler.load_esc_file(
			object.node.esc_script
		)
		object.events = script.events
	
	objects[object.global_id] = object


# Check wether an object was registered
#
# #### Parameters
#
# - global_id: Global ID of object
# **Returns** Wether the object exists in the object registry
func has(global_id: String) -> bool:
	return objects.has(global_id)


# Get the object from the object registry
#
# #### Parameters
#
# - global_id: The global id of the object to retrieve
# **Returns** The retrieved object, or null if not found 
func get_object(global_id: String) -> ESCObject:
	if objects.has(global_id):
		return objects[global_id]
	else:
		escoria.logger.report_warnings(
			"esc_object_manager.gd:get_object()",
			[
				"Invalid object retrieved",
				"Object with global id %s not found" % global_id
			]
		)
		return null
		
		
# Remove an object from the registry
#
# #### Parameters
#
# - object: The object to unregister
func unregister_object(object: ESCObject) -> void:
	if not escoria.inventory_manager.inventory_has(object.global_id) \
			and not object.global_id in RESERVED_OBJECTS:
		objects.erase(object.global_id)
	else:
		if not object.global_id in RESERVED_OBJECTS:
			# Re-instance the node if it is an item present in inventory.
			objects[object.global_id].node = objects[object.global_id].node \
				.duplicate()


# Remove an object from the registry by global_id
#
# #### Parameters
#
# - global_id: The global_id of the object to unregister
func unregister_object_by_global_id(global_id: String) -> void:
	unregister_object(ESCObject.new(global_id, null))


# Insert data to save into savegame.
#
# #### Parameters
#
# - p_savegame: The savegame resource
func save_game(p_savegame: ESCSaveGame) -> void:
	p_savegame.objects = {}
	for obj_global_id in objects:
		if !objects[obj_global_id] is ESCObject:
			continue
		p_savegame.objects[obj_global_id] = \
			objects[obj_global_id].get_save_data()


func get_start_location() -> ESCLocation:
	for object in objects.values():
		if is_instance_valid(object.node) \
				and object.node is ESCLocation \
				and object.node.is_start_location:
			return object
	escoria.logger.report_warnings(
			"esc_object_manager.gd:get_start_location()",
			[
				"Room has no ESCLocation node with 'is_start_location' enabled.",
				"Player will be set at position (0,0) by default."
			]
		)
	return null
