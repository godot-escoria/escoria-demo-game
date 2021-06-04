# A manager for ESC objects
extends Node
class_name ESCObjectManager


const RESERVED_OBJECTS = [
	"bg_music"
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
# - object: Obejct to register
# - force: Register the object, even if it has already been registered
func register_object(object: ESCObject, force: bool = false) -> void:
	if objects.has(object.global_id) and not force:
		escoria.logger.report_errors(
			"ESCObjectManager.register_object: Object already registered",
			[
				"Object with global id %s already registered" % 
						object.global_id
			]
		)
	else:
		if not object.node.is_connected(
			"tree_exited", 
			self, 
			"unregister_object"
		):
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
func get_object(global_id: String) -> ESCObject:
	if objects.has(global_id):
		return objects[global_id]
	else:
		escoria.logger.report_warnings(
			"Invalid object retrieved",
			[
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
