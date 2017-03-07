tool

export(NodePath) var terrain_nodepath
export(Vector2) var front_pos
export var use_custom_z = false
var terrain_node
var pos2DZ

func init_mask():
	if terrain_node == null:
		return
	
	if (has_node("front_pos")):
		pos2DZ = get_node("front_pos").get_global_pos()
	else:
		pos2DZ = front_pos
		
	var scale
	if (!use_custom_z):
		scale = terrain_node.get_terrain(pos2DZ)
	else:
		scale = get_z()
		
	set_z_range_min( 1 ) 
	set_z_range_max( scale )
	update()

	#debug_print_z()

func debug_print_z():
	printt("MASKS node Z : ", get_z())
	printt("node", "name", "Z", "Z_range_min", "Z_range_max")
	printt("node", get_name(), get_z(), get_z_range_min(), get_z_range_max())
	print("\n")

func _ready():
	if (terrain_nodepath != null):
		terrain_node = get_node(terrain_nodepath)
	init_mask()
	#debug_print_z()
	pass


