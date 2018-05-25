extends EditorPlugin

# Returns true if this plugin handles the type of object calling
func handles(object):
	return object.get_class() in managed_types()

# Returns the name of the plugin.
func get_name():
	return "animations_spine"

# Returns the type of plugin. Should be a type defined in Escoria's globals/escoria_items.gd.
func escoria_plugin_type():
	return esc_type.PLUGIN_ANIMATION

# Returns the list of types the plugin deals with.
func managed_types():
	return [ "Spine" ]

# Overriden function to find the sprites contained by the node.
# Returns the list of sprites
func _find_sprites(p = null):
	if p == null:
		return
	
	var sprites = []
	if p.get_class() in managed_types():
		sprites.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_sprites(p.get_child(i))
	
	return sprites


# Method called to connect the 'animation_node''s animation_finished() event
# to the given 'manager_node''s 'call_func_name' function.
# Basically, verifies that this plugin is the right one to manage the provided animation_node.
func _connect_animation_finished_node(animation_node, manager_node, call_func_name):
	if handles(animation_node):
		animation_node.connect("animation_end", manager_node, call_func_name)


# Method called to play the animation in 'animation_node' using the parameters
# defined in parameter 'args'
func _animation_play(animation_node, last_dir, args):
	if handles(animation_node):
		# play(const String &p_name, bool p_loop, int p_track, int p_delay)
		var name = args["name"]
		var loop = args["loop"] if args.has("loop") else false
		var track = args["track"] if args.has("track") else 0
		var delay = args["delay"] if args.has("delay") else 0

		animation_node.play(name, loop, track, delay)
		animation_node.add(animation_node.idles[last_dir], true)


# Function called when animation finishes, to prevent glitches
# depending on the 'task' value.
# The return of this function depends on every plugin. It is better to explain here the reasons
# of the returned value. By default, if there is no reason to have a specific blocking at this moment,
# this function should return false by default.
func _animation_finished_task_is_blocking(task, animation):
	# Spine will call this with track_number instead of animation name,
	# and only track 0 is supported)
	
	# This prevents Spine from breaking and restarting a loop, to
	# avoid a glitch in the walk animation
	if task == "walk" && handles(animation):
		return true
	else:
		return false
