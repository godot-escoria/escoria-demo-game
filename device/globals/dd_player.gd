extends ResourcePreloader

func start(params, level):
	var type
	if params.size() < 2 || !has_resource(params[1]):
		type = "default"
	else:
		type = params[1]

	type = type + ProjectSettings.get_setting("escoria/platform/dialog_type_suffix")

	printt("******* instancing dialog ", type)

	var type_resource = get_resource(type)
	# De-instantiated in dialog_dialog.gd stop() and game_cleared()
	var inst = type_resource.instance()
	get_parent().add_child(inst)

	# check the type and instance it here?
	inst.call_deferred("start", params, level)

func _ready():
	add_to_group("dialog_dialog")

