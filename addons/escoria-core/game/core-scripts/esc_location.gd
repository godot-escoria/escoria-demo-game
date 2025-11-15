@tool
@icon("res://addons/escoria-core/design/esc_location.svg")
## A simple node extending Position2D with a global ID so that it can be
## referenced in ESC Scripts. Movement-based commands like `walk_to_pos` will
## automatically use an `ESCLocation` that is a child of the destination node.
## Commands like `turn_to`--which are not movement-based--will ignore child
## `ESCLocation`s and refer to the parent node.
extends Marker2D
class_name ESCLocation


## Escoria Plugin signal emitted to the `ESCRoom` when a start location is set in the `ESCLocation` node in order to check whether multiple start locations are set.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |node_to_ignore|`ESCLocation`| `ESCLocation` that should be ignored while validating start locations. Defaults to `null`.|no|[br]
## [br]
signal editor_is_start_location_set(node_to_ignore: ESCLocation)

## Warning message: multiple start locations set in the room..
const MULTIPLE_START_LOCATIONS_WARNING = \
	"Only 1 ESCLocation should have is_start_location set to true in an ESCRoom"


## The global ID of this ESCLocation
@export var global_id: String

## If enabled, this `ESCLocation` is considered as a player start location
## for this room.
@export var is_start_location: bool = false:
	set = set_is_start_location


@export_group("Player behavior on arrival")

## Whether player character orients towards 'interaction_angle' as it arrives at
## the item's interaction position.
@export var player_orients_on_arrival: bool = true

## If 'player_orients_on_arrival' is enabled, let the player character turn to
## this angle when it arrives at the item's interaction position.
@export var interaction_angle: int

@export_group("","")

## Escoria plugin variable to check the existence of multiple start locations.
var _multiple_start_locations_exist: bool = false:
	set = set_multiple_start_locations_exist


## Used by "is" keyword to check whether a node's class_name  is the same as p_classname. ## Parameters p_classname: String class to compare against[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_classname|`String`|Class name to compare against this location.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `bool` value. (`bool`)
func is_class(p_classname: String) -> bool:
	return p_classname == "ESCLocation"


## Ready function. Registers the ESCLocation to Object Manager.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _ready():
	if not Engine.is_editor_hint():
		if not self.global_id.is_empty():
			escoria.object_manager.register_object(
				ESCObject.new(
					self.global_id,
					self
				)
			)

## Escoria editor plugin: on tree exit (ie. this node was removed), notify ESCRoom to update the list of start locations.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _exit_tree():
	if Engine.is_editor_hint() and is_start_location:
			editor_is_start_location_set.emit(self)

## Escoria editor plugin: overriden method that returns the list of warnings for these nodes.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `PackedStringArray` value. (`PackedStringArray`)
func _get_configuration_warnings() -> PackedStringArray:
	return [MULTIPLE_START_LOCATIONS_WARNING] \
		if _multiple_start_locations_exist else []

## Escoria editor plugin: Setter for _multiple_start_locations_exist member. Updates the warnings displayed in the editor's scene tree.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |value|`bool`|true whether multiple start locations exist in the room.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_multiple_start_locations_exist(value: bool) -> void:
	_multiple_start_locations_exist = value
	update_configuration_warnings()

## Escoria editor plugin: Setter for is_start_location member. Notifies the ESCRoom of the change.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |value|`bool`|true whether the ESCLocation node was set as start location.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_is_start_location(value: bool) -> void:
	is_start_location = value
	if Engine.is_editor_hint() and is_instance_valid(get_owner()):
		editor_is_start_location_set.emit()
