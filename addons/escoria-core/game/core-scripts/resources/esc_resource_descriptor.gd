# Describes a resource for use in the resource cache
extends Resource
class_name ESCResourceDescriptor


# The resource being described
var res: Resource

# Whether the resource is permanent
var permanent: bool


func _init(res_in: Resource, permanent_in: bool) -> void:
	res = res_in
	permanent = permanent_in
