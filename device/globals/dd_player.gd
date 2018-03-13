extends ResourcePreloader

var dialogs = {}

func start(params, level):
	var type
	if params.size() < 2 || !has_resource(params[1]):
		type = "default"
	else:
		type = params[1]

	type = type + ProjectSettings.get_setting("escoria/platform/dialog_type_suffix")

	printt("******* instancing dialog ", type)

	if not type in dialogs:
		return

	var inst = dialogs[type].instance()
	get_parent().add_child(inst)

	# check the type and instance it here?
	inst.call_deferred("start", params, level)

func _init():
	add_to_group("dialog_dialog")
	for res in get_resource_list():
		dialogs[res] = get_resource(res)