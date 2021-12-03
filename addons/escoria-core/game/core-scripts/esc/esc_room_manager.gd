extends Object
class_name ESCRoomManager


# Reserved globals which can not be overridden; prefixed with "GLOBAL_"
#
# Contains the global_id of previous room
const GLOBAL_LAST_SCENE = "ESC_LAST_SCENE"

# If true, ESC_LAST_SCENE is not considered for automatic transitions
const GLOBAL_FORCE_LAST_SCENE_NULL = "FORCE_LAST_SCENE_NULL"

const GLOBAL_ANIMATION_RESOURCES = "ANIMATION_RESOURCES"

# Contains the global_id of the current room
const GLOBAL_CURRENT_SCENE = "ESC_CURRENT_SCENE"

# Dict of the reserved globals to register and their initial values.
const RESERVED_GLOBALS = {
	GLOBAL_LAST_SCENE: "",
	GLOBAL_FORCE_LAST_SCENE_NULL: false,
	GLOBAL_ANIMATION_RESOURCES: [],
	GLOBAL_CURRENT_SCENE: ""
}


# Registers all reserved global flags for use.
func register_reserved_globals() -> void:
	for key in RESERVED_GLOBALS:
		escoria.globals_manager.register_reserved_global( \
			key, 
			RESERVED_GLOBALS[key])
