# Manages currently carried out actions
extends Resource
class_name ESCActionManager


# The current action verb was changed
signal action_changed

# Emitted, when an action has been completed
signal action_finished

# Emitted when the action input state has changed
signal action_input_state_changed


# States of the action input (verb, item, target)
# (I) -> AWAITING_VERB_OR_ITEM -> AWAITING_ITEM -> COMPLETED -> (E)
# or
# (I) -> AWAITING_VERB_OR_ITEM -> AWAITING_ITEM -> AWAITING_TARGET_ITEM -> COMPLETED -> (E)
# or
# (I) -> AWAITING_VERB_OR_ITEM -> AWAITING_VERB -> AWAITING_VERB_CONFIRMATION -> COMPLETED -> (E)
enum ACTION_INPUT_STATE {
	# Initial state
	AWAITING_VERB_OR_ITEM,
	# After initial state, verb is defined
	AWAITING_ITEM,
	# Item defined requires combine, waiting for  target
	AWAITING_TARGET_ITEM
	# After initial state, item is defined
	AWAITING_VERB,
	# Item was defined first, next verb, need verb confirmation
	AWAITING_VERB_CONFIRMATION,
	# Final state
	COMPLETED
}

# Actions understood by the do(...) method
# * BACKGROUND_CLICK: Object is to move from its current position
# * ITEM_LEFT_CLICK: Item has been clicked on with LMB.
# * ITEM_RIGHT_CLICK: Item has been clicked on with RMB.
# * TRIGGER_IN: Character has moved into a trigger area.
# * TRIGGER_OUT: Character has moved out of a trigger area.
enum ACTION {
	BACKGROUND_CLICK,
	ITEM_LEFT_CLICK,
	ITEM_RIGHT_CLICK,
	TRIGGER_IN,
	TRIGGER_OUT
}


# Basic required internal actions
const ACTION_ARRIVED = "arrived"
const ACTION_EXIT_SCENE = "exit_scene"
const ACTION_WALK = "walk"


# Current verb used
var current_action: String = "" setget set_current_action

# Current tool (ESCItem/ESCInventoryItem) used
var current_tool: ESCObject

# Current target where the tool is being used on/with (if any)
var current_target: ESCObject

# Current action input state
var action_state = ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM \
		setget set_action_input_state


# Run a generic action
#
# #### Parameters
#
# - action: type of the action to run
# - params: Parameters for the action
# - can_interrupt: if true, this command will interrupt any ongoing event
# before it is finished
func do(action: int, params: Array = [], can_interrupt: bool = false) -> void:
	if escoria.current_state == escoria.GAME_STATE.DEFAULT:
		match action:
			ACTION.BACKGROUND_CLICK:
				if can_interrupt:
					escoria.event_manager.interrupt()

				var walk_fast = false
				if params.size() > 2:
					walk_fast = true if params[2] else false

				# Check moving object.
				if not escoria.object_manager.has(params[0]):
					escoria.logger.error(
						self,
						"Walk action requested for nonexisting object: %s."
								% params[0]
					)
					return

				var moving_obj = escoria.object_manager.get_object(params[0])
				var target

				if params[1] is String:
					if not escoria.object_manager.has(params[1]):
						escoria.logger.error(
							self,
							"Walk action requested to nonexisting destination object: %s."
									% params[1]
						)
						return

					target = escoria.object_manager.get_object(params[1])
				elif params[1] is Vector2:
					target = params[1]

				self.perform_walk(moving_obj, target, walk_fast)

			ACTION.ITEM_LEFT_CLICK:
				if params[0] is String:
					escoria.logger.info(
						self,
						"item_left_click on item %s." % params[0]
					)

					if can_interrupt:
						escoria.event_manager.interrupt()

					var item = escoria.object_manager.get_object(params[0])

					self.perform_inputevent_on_object(item, params[1])

			ACTION.ITEM_RIGHT_CLICK:
				if params[0] is String:
					escoria.logger.info(
						self,
						"item_right_click on item %s." % params[0]
					)

					if can_interrupt:
						escoria.event_manager.interrupt()

					var item = escoria.object_manager.get_object(params[0])

					self.perform_inputevent_on_object(item, params[1], true)

			ACTION.TRIGGER_IN:
				var trigger_id = params[0]
				var object_id = params[1]
				var trigger_in_verb = params[2]
				escoria.logger.info(
					self,
					"trigger_in on trigger %s activated by %s." % [
						trigger_id,
						object_id
					]
				)
				escoria.event_manager.queue_event(
					escoria.object_manager.get_object(trigger_id).events[
						trigger_in_verb
					]
				)

			ACTION.TRIGGER_OUT:
				var trigger_id = params[0]
				var object_id = params[1]
				var trigger_out_verb = params[2]
				escoria.logger.info(
					self,
					"trigger_out on trigger %s activated by %s." % [
						trigger_id,
						object_id
					]
				)
				escoria.event_manager.queue_event(
					escoria.object_manager.get_object(trigger_id).events[
						trigger_out_verb
					]
				)

			_:
				escoria.logger.warn(
					self,
					"Action received: %s with params %s.", [action, params]
				)
	elif escoria.current_state == escoria.GAME_STATE.WAIT:
		pass


# Sets the current state of action input.
#
# ## Parameters
# - p_state: the action input state to set
func set_action_input_state(p_state):
	action_state = p_state
	emit_signal("action_input_state_changed")


# Set the current action verb
#
# ## Parameters
# - action: The action verb to set
func set_current_action(action: String):
	if action != current_action:
		clear_current_tool()

	current_action = action

	if action_state == ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM:
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_ITEM)
	elif action_state == ACTION_INPUT_STATE.AWAITING_VERB:
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_VERB_CONFIRM)

	emit_signal("action_changed")


# Clear the current action
func clear_current_action():
	set_current_action("")
	set_action_input_state(ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM)
	emit_signal("action_changed")


# Clear the current tool
func clear_current_tool():
	current_tool = null
	current_target = null
	if action_state == ACTION_INPUT_STATE.AWAITING_VERB:
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM)
	elif action_state == ACTION_INPUT_STATE.AWAITING_TARGET_ITEM:
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_ITEM)


# Activates the action for given params
#
# #### Parameters
#
# - action String Action to execute (defined in attached ESC file and in
#   action verbs UI) eg: arrived, use, look, pickup...
# - target: Target ESC object
# - combine_with: ESC object to combine with
func _activate(
	action: String,
	target: ESCObject,
	combine_with: ESCObject = null
) -> int:
	escoria.logger.info(
		self,
		"Activated action %s on %s." % [action, target]
	)

	# If we're using an action which item requires to combine
	if target.node is ESCItem\
			and action in target.node.combine_when_selected_action_is_in:
		# Check if object must be in inventory to be used
		if target.node.use_from_inventory_only:
			if escoria.inventory_manager.inventory_has(target.global_id):
				# Player has item in inventory, we check the element to use on
				if combine_with:
					var do_combine = true
					if combine_with.node is ESCItem \
							and combine_with.node.use_from_inventory_only\
							and not escoria.inventory_manager.inventory_has(
								combine_with.global_id
							):
						do_combine = false

					if do_combine:
						var target_event = "%s %s" % [
							action,
							combine_with.global_id
						]
						var combine_with_event = "%s %s" % [
							action,
							target.global_id
						]
						if target.events.has(target_event):
							escoria.event_manager.queue_event(target.events[
								target_event
							])
							var event_returned = yield(
								escoria.event_manager,
								"event_finished"
							)
							while event_returned[1] != target_event:
								event_returned = yield(
									escoria.event_manager,
									"event_finished"
								)
							if event_returned[0] == ESCExecution.RC_OK:
								escoria.action_manager.clear_current_action()
							emit_signal("action_finished")
							return event_returned[0]
						elif combine_with.events.has(combine_with_event)\
								and not combine_with.node.combine_is_one_way:
							escoria.event_manager.queue_event(
								combine_with.events[
									combine_with_event
								]
							)
							var event_returned = yield(
								escoria.event_manager,
								"event_finished"
							)
							while event_returned[1] != combine_with_event:
								event_returned = yield(
									escoria.event_manager,
									"event_finished"
								)
							if event_returned[0] == ESCExecution.RC_OK:
								escoria.action_manager.clear_current_action()
							emit_signal("action_finished")
							return event_returned[0]
						else:
							var errors = [
								"Attempted to execute action %s between item %s and item %s" % [
									action,
									target.global_id,
									combine_with.global_id
								]
							]
							if combine_with.node.combine_is_one_way:
								errors.append(
									("Reason: %s's item interaction " +\
									"is one-way.") % combine_with.global_id
								)
							escoria.logger.warn(
								self,
								"Invalid action" + str(errors)
							)
							emit_signal("action_finished")
							return ESCExecution.RC_ERROR
					else:
						escoria.logger.warn(
							self,
							"Invalid action on item: " +
								(
									"Trying to combine object %s with %s, "+
									"but %s is not in inventory."
								) % [
									target.global_id,
									combine_with.global_id,
									combine_with.global_id
								]
						)
						emit_signal("action_finished")
						return ESCExecution.RC_ERROR
				else:
					# We're missing a target here for our tool to be used on
					current_tool = target
					set_action_input_state(
						ACTION_INPUT_STATE.AWAITING_TARGET_ITEM
					)
					return ESCExecution.RC_OK
			else:
				escoria.logger.warn(
					self,
					"Invalid action on item" +
					"Trying to run action %s on object %s, " %
					[
						action,
						target.node.global_id
					]
					+ "but item must be in inventory."
				)

	if target.events.has(action):
		escoria.event_manager.queue_event(target.events[action])
		var event_returned = yield(
			escoria.event_manager,
			"event_finished"
		)
		while event_returned[1] != action:
			event_returned = yield(
				escoria.event_manager,
				"event_finished"
			)
		if event_returned[0] == ESCExecution.RC_OK:
			clear_current_action()
		emit_signal("action_finished")
		return event_returned[0]
	else:
		escoria.logger.warn(
			self,
			"Invalid action: " +
				"Event for action %s on object %s not found." % [
					action,
					target.global_id
				]
		)
		emit_signal("action_finished")
		return ESCExecution.RC_ERROR


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
				target_position = destination.node.get_interact_position()

			var walk_context = ESCWalkContext.new(
				destination,
				target_position,
				is_fast,
				true
			)

			moving_obj.node.walk_to(target_position, walk_context)

	else:
		escoria.logger.error(
			self,
			"Function expected either a Vector2 or ESCObject type " + \
			"for destination parameter. Destination provided was: %s." % destination
		)
		return


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

	escoria.logger.info(
		self,
		"%s to perform event %s." % [obj.global_id, event]
	)

	var event_flags = 0
	var has_current_action: bool = false
	if obj.events.has(current_action):
		event_flags = obj.events[current_action].flags
		has_current_action = true

	# Don't interact after player movement towards object
	# (because object is inactive for example)
	var dont_interact = false

	# We need to have the new action input state BEFORE initiating the player
	# move so we determine now if the object clicked will require a combination
	# depending on the used action verb.
	var tool_just_set = _set_tool_and_action(obj, default_action)
	var need_combine = _check_item_needs_combine()

	# If the current tool was not set, this is our first item, make it tool
	if not current_tool or (current_tool and not need_combine):
		current_tool = obj
	# Else, if we have a tool an combination required, this is our second item,
	# make it target.
	elif need_combine and not tool_just_set:
		current_target = obj

	# Update the action input state
	if action_state == ACTION_INPUT_STATE.AWAITING_TARGET_ITEM and current_target:
		set_action_input_state(ACTION_INPUT_STATE.COMPLETED)
	elif action_state == ACTION_INPUT_STATE.AWAITING_ITEM and \
			not need_combine:
		set_action_input_state(ACTION_INPUT_STATE.COMPLETED)
	elif action_state == ACTION_INPUT_STATE.AWAITING_ITEM and need_combine and not tool_just_set:
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_TARGET_ITEM)

	if escoria.main.current_scene.player:
		var destination_position: Vector2 = escoria.main.current_scene.player.\
				global_position

		# If clicked object not in inventory, player walks towards it
		if not obj.node is ESCPlayer and \
			not escoria.inventory_manager.inventory_has(obj.global_id) and \
			(not has_current_action or not event_flags & ESCEvent.FLAG_TK):
				var context = _walk_towards_object(
					obj,
					event.position,
					event.doubleclick
				)
				if context is GDScriptFunctionState:
					context = yield(context, "completed")

				# In case of an interrupted walk, we don't want to proceed.
				if context == null:
					return

				destination_position = context.target_position
				dont_interact = context.dont_interact_on_arrival

		var player_global_pos = escoria.main.current_scene.player.global_position
		var clicked_position = event.position

		if not player_global_pos.is_equal_approx(destination_position):
			dont_interact = true
			escoria.logger.info(
				self,
				"Player could not reach destination coordinates %s. "  % str(destination_position) \
					+ "Any requested action for %s will not fire." % obj.global_id
			)
			if escoria.event_manager.EVENT_CANT_REACH in obj.events:
				escoria.event_manager.queue_event(obj.events[escoria.event_manager.EVENT_CANT_REACH])
			else:
				escoria.logger.info(
					self,
					"%s event not found for object %s so nothing to do." % \
						[escoria.event_manager.EVENT_CANT_REACH, obj.global_id]
				)


	# If no interaction should happen after player has arrived, leave
	# immediately.
	if dont_interact:
		return

	# Manage exits
	if obj.node.is_exit and current_action in ["", ACTION_WALK]:
		_activate(ACTION_EXIT_SCENE, obj)
	else:
		# Manage movements towards object before activating it
		if current_action in ["", ACTION_WALK] and \
				not escoria.inventory_manager.inventory_has(obj.global_id):
			_activate(ACTION_ARRIVED, obj)
		# Manage action on object
		elif not current_action in ["", ACTION_WALK]:
			if need_combine and current_target:
				_activate(
					current_action,
					current_tool,
					current_target
				)

			else:
				_activate(
					current_action,
					obj
				)


# Determines whether the object in question can be acted upon.
#
# #### Parameters
#
# - global_id: the global ID of the item to examine
#
# *Returns* True iff the item represented by global_id can be acted upon.
func is_object_actionable(global_id: String) -> bool:
	var obj: ESCObject = escoria.object_manager.get_object(global_id) as ESCObject

	return _is_object_actionable(obj)


# Prepare the "obj" object for current_action: if required, set the object as
# current tool.
#
# #### Parameters
#
# - obj: the ESCObject to prepare
# - default_action: if true, the default action set on the item is used
#
# *Returns* True if the tool was set in this function
func _set_tool_and_action(obj: ESCObject, default_action: bool):
	var tool_just_set: bool = false
	# Check if current_action and current_tool are already set
	if current_action and current_tool:
		if not current_action in escoria.action_manager\
				.current_tool.node.combine_when_selected_action_is_in:
			current_tool = obj
			tool_just_set = true
	elif default_action:
		if escoria.inventory_manager.inventory_has(obj.global_id):
			current_action = obj.node.default_action_inventory
		else:
			current_action = obj.node.default_action
	elif current_action in obj.node.combine_when_selected_action_is_in:
		current_tool = obj
		tool_just_set = true
	return tool_just_set


# Checks if object requires a combination with another, according to
# currently selected action verb (or check with default action of the item).
#
# *Returns* True if current action on "obj" requires a combination
func _check_item_needs_combine() -> bool:
	return current_action \
			and current_tool \
			and current_action in current_tool.node.combine_when_selected_action_is_in


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

	if obj == null || obj.node == null:
		escoria.logger.error(
			self,
			"walk_towards_object error. obj or obj.node not populated."
		)
	var interact_position = obj.node.get_interact_position()
	# If clicked object is interactive, get destination position from it.
	if escoria.object_manager.get_object(obj.global_id).interactive:
		if interact_position != null:
			destination_position = interact_position
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

	escoria.logger.debug(
	self,
	"Player walking to destination. Yielding."
)

	# Wait for the player to arrive before continuing with action.
	var context: ESCWalkContext = yield(
		escoria.main.current_scene.player,
		"arrived"
	)

	if context.target_object != obj:
		escoria.logger.debug(
			self,
			"Original walk context target does not match " \
					+ "yielded walk context. Likely interrutped walk.")
		return

	escoria.logger.info(
		self,
		"Context arrived: %s." % context
	)

	# Confirm that reached item was the one user clicked in the first place.
	# Don't interact if that is not the case.
	if (context.target_object and context.target_object.\
			global_id != walk_context.\
			target_object.global_id) or \
		(context.target_position != walk_context.target_position):
		walk_context.dont_interact_on_arrival = true

	return context


# Determines whether the object in question can be acted upon.
#
# #### Parameters
#
# - obj: the ESCObject to examine
#
# *Returns* True iff 'obj' can be acted upon.
func _is_object_actionable(obj: ESCObject) -> bool:
	var object_is_actionable: bool = true

	if not obj:
		return false

	if not obj.active:
		escoria.logger.debug(
			self,
			"Item %s is not active." % obj.global_id
		)
		object_is_actionable = false
	elif not obj.interactive:
		escoria.logger.debug(
			self,
			"Item %s is not interactive." % obj.global_id
		)
		object_is_actionable = false

	return object_is_actionable
