extends ResourcePreloader

var types = {}

func say(params, callback):
	var type
	if params.size() < 3 || !has_resource(params[2]):
		type = "default"
	else:
		type = params[2]
	type = type + ProjectSettings.get_setting("escoria/platform/dialog_type_suffix")
	var inst = get_resource(type).instance()
	get_parent().add_child(inst)
	var intro = true
	var outro = true
	if type in types:
		intro = types[type][0]
		outro = types[type][1]
	inst.init(params, callback, intro, outro)

func config(params):
	types[params[0]] = [params[1], params[2]]

func _ready():
	add_to_group("dialog")
