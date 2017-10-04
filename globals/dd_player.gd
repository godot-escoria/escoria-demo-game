
func start(params, level):
	var type
	if params.size() < 2 || !has_resource(params[1]):
		type = "default"
	else:
		type = params[1]

	type = type + ProjectSettings.get("platform/dialog_type_suffix")

	printt("******* instancing dialog ", type)

	var inst = get_resource(type).instance()
	get_parent().add_child(inst)

	# check the type and instance it here?
	inst.call_deferred("start", params, level)

func _ready():
	add_to_group("dialog_dialog")
