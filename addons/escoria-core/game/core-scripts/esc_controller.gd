# This script contains functions called by gamedev's game.gd.
# These functions convert input actions into game actions. For example:
# "click on background" -> player walks to position
# "click on item" -> player walks to item then performs the action defined
# by current verb

class_name ESCController


# Makes an object walk to a destination. This can be either a 2D position or
# another object.
#
# #### Parameters
#
# - moving_obj_id: global id of the object that needs to move
# - destination: Position2D or ESCObject holding the moving object to head to
# - is_fast: if true, the walk is performed at fast speed (defined in the moving
# object.
func perform_walk(
	moving_obj: ESCObject, 
	destination, 
	is_fast: bool = false
):
	# Walk to Position2D.
	if destination is Vector2:
		var walk_context = ESCWalkContext.new(
			null,
			destination,
			is_fast,
			true
		) 
		moving_obj.node.walk_to(destination, walk_context)
		
	# Walk to object
	elif destination is ESCObject:
		if destination.node:
			var target_position: Vector2
			if destination.node is ESCLocation:
				target_position = destination.node.global_position
			else:
				target_position = destination.node.interact_position
				
			var walk_context = ESCWalkContext.new(
				destination.node, 
				Vector2(), 
				is_fast,
				true
			)
			
			moving_obj.node.walk_to(target_position, walk_context)


# Event handler when an object/item was clicked
#
# #### Parameters
#
# - obj: Object that was left clicked
# - event: Input event that was received
# - default_action: if true, run the inventory default action
func perform_inputevent_on_object(
	obj: ESCObject, 
	event: InputEvent, 
	default_action: bool = false
):
	"""
	This algorithm:
	- makes the player move to the clicked object location, if needed 
	(if it is located in the room for example) and wait for reaching.
	- when reached, performs an action depending on current defined action 
		* no current action defined: do nothing else
		* current action defined: 
			* item requires no combination: perform the current action 
			  on the item
			* item requires combination: check the status of the combination 
			  A combination requires 3 elements to fulfill:
				1/ a verb action
				2/ a first "tool" (item to use)
				3/ a second "tool" (item to use ON)
			  Whatever the user inputs to fulfill the combination (this is
			  determined by gamedev in his game.gd script)
				- combination not fulfilled: no not perform until fulfilled
				- combination fulfilled: perform the combination.
		* else do nothing, except if default_action is requested.
		  In this case, perform the default_action on the item.
	"""
	
	escoria.logger.info("%s left-clicked with event " % obj.global_id, [event])
	
	# Don't interact after player movement towards object 
	# (because object is inactive for example)
	var dont_interact = false
	
	var destination_position: Vector2 = escoria.main.current_scene.player.\
			global_position
	
	# If clicked object not in inventory, player walks towards it
	if not escoria.inventory_manager.inventory_has(obj.global_id):
		var context = _walk_towards_object(
			obj, 
			event.position, 
			event.doubleclick
		)
		if context is GDScriptFunctionState:
			context = yield(_walk_towards_object(
				obj, 
				event.position, 
				event.doubleclick
			), "completed")
		destination_position = context.target_position
		dont_interact = context.dont_interact_on_arrival
	
	# If no interaction should happen after player has arrived, leave 
	# immediately.
	if dont_interact:
		return
	
	var player_global_pos = escoria.main.current_scene.player.global_position
	var clicked_position = event.position
	
	# If player has arrived at the position he was supposed to reach 
	# so he can interact
	if player_global_pos == destination_position:
		# Manage exits
		if obj.node.is_exit and escoria.action_manager.current_action \
				in ["", "walk"]:
			escoria.action_manager.activate("exit_scene", obj)
		else:
			# Manage movements towards object before activating it
			if escoria.action_manager.current_action in ["", "walk"] and \
				not escoria.inventory_manager.inventory_has(obj.global_id):
					escoria.action_manager.activate("arrived", obj)
			# Manage action on object
			elif not escoria.action_manager.current_action in ["", "walk"]:
				# Check if clicked item awaits a combination
				var need_combine = _check_item_needs_combine(
					obj, 
					default_action
				)
				
				# If apply_interact, perform combine between items
				if need_combine:
					escoria.action_manager.activate(
						escoria.action_manager.current_action,
						escoria.action_manager.current_tool,
						obj
					)
						
				else:
					escoria.action_manager.activate(
						escoria.action_manager.current_action,
						obj
					)

# Checks if object requires a combination with another, according to 
# currently selected action verb (or check with default action of the item).
# 
# #### Parameters
#
# - obj: the ESCObject to test
# - default_action: if true, the check is done on the object's default action
func _check_item_needs_combine(obj: ESCObject, default_action: bool) -> bool:
	var need_combine = false
	# Check if current_action and current_tool are already set
	if escoria.action_manager.current_action and \
		escoria.action_manager.current_tool:
			if escoria.action_manager.current_action in escoria.action_manager\
					.current_tool.node.combine_if_action_used_among:
				need_combine = true
			else:
				escoria.action_manager.current_tool = obj
	elif default_action:
		if escoria.inventory_manager.inventory_has(obj.global_id):
			escoria.action_manager.current_action = \
					obj.node.default_action_inventory
		else:
			escoria.action_manager.current_action = \
					obj.node.default_action
	elif escoria.action_manager.current_action in \
			obj.node.combine_if_action_used_among:
		escoria.action_manager.current_tool = obj
	return need_combine


# Makes the player character walk towards the clicked item. 
# Returns the resulting walk context.
#
# #### Parameters
#
# - obj: the object that was clicked
# - clicked_position: the Position2D of the input click
# - walk_fast: if true, the player will walk fast to the object
func _walk_towards_object(
	obj: ESCObject, 
	clicked_position: Vector2,
	walk_fast: bool
) -> ESCWalkContext:
	var destination_position: Vector2
	var dont_interact: bool = false

	# If clicked object is interactive, get destination position from it.
	if escoria.object_manager.get_object(obj.global_id).interactive:
		if obj.node.get_interact_position() != null:
			destination_position = obj.node.get_interact_position()
		else:
			destination_position = obj.node.position
	else:
		destination_position = clicked_position
		dont_interact = true
		
	# Create walk context 
	var walk_context = ESCWalkContext.new(
		obj,
		destination_position,
		walk_fast,
		dont_interact
	)
	
	# Walk towards the clicked object
	escoria.main.current_scene.player.walk_to(destination_position, 
		walk_context)
	
	# Wait for the player to arrive before continuing with action.
	var context: ESCWalkContext = yield(
		escoria.main.current_scene.player,
		"arrived"
	)
	escoria.logger.info("Context arrived: %s" % context)
	
	# Confirm that reached item was the one user clicked in the first place.
	# Don't interact if that is not the case. 
	if (context.target_object and context.target_object.\
			global_id != walk_context.\
			target_object.global_id) or \
		(context.target_position != walk_context.target_position):
		walk_context.dont_interact_on_arrival = true
	
	return context
