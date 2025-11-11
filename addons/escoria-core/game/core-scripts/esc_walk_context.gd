## The walk context describes the target of a walk command and if that command
## should be executed fast.
extends RefCounted
class_name ESCWalkContext


## Target object that the walk command tries to reach.
var target_object: ESCObject = null

## The target position
var target_position: Vector2 = Vector2()

## Whether to move fast
var fast: bool

## Whether an interaction should NOT happen after walk reaches destination
var dont_interact_on_arrival: bool

## Constructor method.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_target_object|`ESCObject`|Escoria object the walker should approach (or `null` when walking to a position).|yes|[br]
## |p_target_position|`Vector2`|World position the walker should reach when no target object is provided.|yes|[br]
## |p_fast|`bool`|Whether the walk should use the actor's fast speed.|yes|[br]
## |p_dont_interact_on_arrival|`bool`|If `true`, skip the usual interaction when the destination is reached.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _init(
	p_target_object: ESCObject,
	p_target_position: Vector2,
	p_fast: bool,
	p_dont_interact_on_arrival: bool
):
	target_object = p_target_object
	target_position = p_target_position
	fast = p_fast
	dont_interact_on_arrival = p_dont_interact_on_arrival
