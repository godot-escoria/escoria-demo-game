extends ResourcePreloader

var types = {}

func say(params, callback):
	var type
	if params.size() < 3 || !has_resource(params[2]):
		type = "default"
	else:
		type = params[2]

	# Zooming will also affect the type. But account for the fact floats are actual floats and hard to compare.
	var zoom_diff = abs(vm.camera.zoom.x - $"/root/scene".default_zoom)
	var need_zoomed = round(zoom_diff) > 0

	# Check if we have an inventory, because it might affect dialog positioning
	if (vm.inventory and vm.inventory.blocks_tooltip()) or need_zoomed:
		type = "bottom"

	type = type + ProjectSettings.get_setting("escoria/platform/dialog_type_suffix")
	var inst = get_resource(type).instance()
	var z = inst.get_z_index()

	if (vm.inventory and vm.inventory.blocks_tooltip()) or need_zoomed:
		inst.fixed_pos = true

	$"/root/scene/game/dialog_layer".add_child(inst)

	var intro = true
	var outro = true
	if type in types:
		intro = types[type][0]
		outro = types[type][1]
	inst.init(params, callback, intro, outro)
	inst.set_z_index(z)

func config(params):
	types[params[0]] = [params[1], params[2]]

func _ready():
	add_to_group("dialog")
