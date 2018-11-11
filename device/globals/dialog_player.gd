extends ResourcePreloader

var types = {}

func say(params, callback):
	# Check if we have an inventory, because it might affect dialog positioning
	var inventory
	if $"/root/scene/game/hud_layer/hud".has_node("inventory"):
		inventory = $"/root/scene/game/hud_layer/hud/inventory"

	var type
	if params.size() < 3 || !has_resource(params[2]):
		type = "default"
	else:
		type = params[2]

	if inventory and inventory.blocks_tooltip():
		# XXX: This can be made into a config option by someone with spare time
		type = "bottom"

	# Zooming will also affect the type.
	if vm.camera.zoom.x != $"/root/scene".default_zoom:
		type = "bottom"

	type = type + ProjectSettings.get_setting("escoria/platform/dialog_type_suffix")
	var inst = get_resource(type).instance()
	var z = inst.get_z_index()

	if inventory and inventory.blocks_tooltip():
		inst.fixed_pos = true

	if vm.camera.zoom.x != $"/root/scene".default_zoom:
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
