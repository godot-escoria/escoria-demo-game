## Describes a resource for use in the resource cache.
extends Resource
class_name ESCResourceDescriptor

## The resource being described.
var res

## Whether the resource is permanent.
var permanent: bool

## Constructor for ESCResourceDescriptor. Sets the resource and permanence flag.[br]
## [br]
## #### Parameters[br]
## [br]
## - res_in: The resource to describe.[br]
## - permanent_in: Whether the resource is permanent.
func _init(res_in, permanent_in: bool) -> void:
	res = res_in
	permanent = permanent_in
