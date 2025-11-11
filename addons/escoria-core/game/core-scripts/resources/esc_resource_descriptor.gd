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
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |res_in|`Variant`|The resource to describe.|yes|[br]
## |permanent_in|`bool`|Whether the resource is permanent.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _init(res_in, permanent_in: bool) -> void:
	res = res_in
	permanent = permanent_in
