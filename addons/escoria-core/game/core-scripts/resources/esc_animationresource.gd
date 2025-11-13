@tool
## Resource containing all defined animations and angles for character
## movement.[br]
extends Resource
class_name ESCAnimationResource

## Array containing the different angles available for animations.[br]
## Each angle is defined by an array [start_angle, angle_size].
## start_angle must be between 0 and 360.[br]
## Angles 0 and 360 are the same and correspond to UP/NORTH, 90 is RIGHT/EAST,
## 180 is DOWN/SOUTH, 270 is LEFT/WEST etc.
@export var dir_angles: Array[ESCDirectionAngle] = []: set = set_dir_angles

## Array of animations for each direction, from UP to RIGHT_UP clockwise.[br]
## Each entry is [animation_name, scale]. The scale parameter can be set to -1 to
## mirror the animation.
@export var directions: Array[ESCAnimationName] = []: set = set_directions

## Array containing the idle animations for each direction (in the order defined
## by dir_angles).[br]
## The scale parameter can be set to -1 to mirror the animation.
@export var idles: Array[ESCAnimationName] = []: set = set_idles

## Array containing the speak animations for each direction (in the order defined
## by dir_angles).[br]
## The scale parameter can be set to -1 to mirror the animation.
@export var speaks: Array[ESCAnimationName] = []: set = set_speaks

## Sets the dir_angles property.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_dir_angles|`Array`|Array of direction angle resources to set.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_dir_angles(p_dir_angles: Array[ESCDirectionAngle]) -> void:
	dir_angles = p_dir_angles
	emit_changed()

## Sets the directions property.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_set_directions|`Array`|Array of direction resources to set.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_directions(p_set_directions: Array[ESCAnimationName]) -> void:
	directions = p_set_directions
	emit_changed()

## Sets the idles property.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_set_idles|`Array`|Array of idle resources to set.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_idles(p_set_idles: Array[ESCAnimationName]) -> void:
	idles = p_set_idles
	emit_changed()

## Sets the speaks property.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_set_speaks|`Array`|Array of speak resources to set.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_speaks(p_set_speaks: Array[ESCAnimationName]) -> void:
	speaks = p_set_speaks
	emit_changed()

## The direction id from an animation name. 1 if not found.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_animation_name|`String`|The animation name.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the direction id from an animation name. 1 if not found. (`int`)
func get_direction_id_from_animation_name(p_animation_name: String) -> int:
	var founds_array = []

	for directions_anim_resource in directions:
		if (directions_anim_resource as ESCAnimationName).animation == p_animation_name:
			founds_array.push_back(directions.find(directions_anim_resource))
	for idles_anim_resource in idles:
		if (idles_anim_resource as ESCAnimationName).animation == p_animation_name:
			founds_array.push_back(idles.find(idles_anim_resource))
	for speaks_anim_resource in speaks:
		if (speaks_anim_resource as ESCAnimationName).animation == p_animation_name:
			founds_array.push_back(speaks.find(speaks_anim_resource))

	if founds_array.size() > 1:
		escoria.logger.warn(
			self,
			"Multiple animations found for name %s. Returning first direction found." % p_animation_name
		)
	elif founds_array.size() == 0:
		return -1
	return founds_array[0]
