# Manages currently carried out actions
extends Resource
class_name ESCActionManager

const ESCPlayer = preload("res://addons/escoria-core/game/core-scripts/esc_player.gd")

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
	AWAITING_TARGET_ITEM,
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
var current_action: String = "": set = set_current_action

# Current tool (ESCItem/ESCInventoryItem) used
var current_tool: ESCObject

# Current target where the tool is being used on/with (if any)
var current_target: ESCObject

# Current action input state
var action_state = ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM:
		set = set_action_input_state

# Run a generic action
#
# #### Parameters
#
# - action: type of the action to run
# - params: Parameters for the action
#    - BACKGROUND_CLICK: [moving_obj, target, walk_fast]
#    - ITEM_LEFT_CLICK: [item, input_event]
#    - ITEM_RIGHT_CLICK: [item, input_event]
#    - TRIGGER_IN: [trigger_id, object_id, trigger_in_verb]
#    - TRIGGER_OUT: [trigger_id, object_id, trigger_out_verb]
# - can_interrupt: if true, this command will interrupt any ongoing event
# before it is finished
func do(action: int, params: Array = [], can_interrupt: bool = false) -> void:
	if escoria.current_state == escoria.GAME_STATE.DEFAULT:
		match action:
			ACTION.BACKGROUND_CLICK:
				if can_interrupt:
					escoria.event_manager.interrupt([], false)

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
						escoria.event_manager.interrupt([], false)

					var item = escoria.object_manager.get_object(params[0])

					self.perform_inputevent_on_object(item, params[1])

			ACTION.ITEM_RIGHT_CLICK:
				if params[0] is String:
					escoria.logger.info(
						self,
						"item_right_click on item %s." % params[0]
					)

					if can_interrupt:
						escoria.event_manager.interrupt([], false)

					var item = escoria.object_manager.get_object(params[0])

					self.perform_inputevent_on_object(item, params[1])

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
				if trigger_in_verb in escoria.object_manager.get_object(trigger_id).events:
					escoria.event_manager.queue_event(
						escoria.object_manager.get_object(trigger_id).events[
							trigger_in_verb
						]
					)
				else:
					escoria.logger.info(
						self,
						"%s event not found for object %s so nothing to do." % \
							[trigger_in_verb, trigger_id])

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
				if trigger_out_verb in escoria.object_manager.get_object(trigger_id).events:
					escoria.event_manager.queue_event(
						escoria.object_manager.get_object(trigger_id).events[
							trigger_out_verb
						]
					)
				else:
					escoria.logger.info(
						self,
						"%s event not found for object %s so nothing to do." % \
							[trigger_out_verb, trigger_id])


			_:
				escoria.logger.warn(
					self,
					"Action received: '%s' with params %s." % [action, params]
				)
	elif escoria.current_state == escoria.GAME_STATE.WAIT:
		pass
	elif escoria.current_state == escoria.GAME_STATE.LOADING:
		pass


# Sets the current state of action input.
#
# ## Parameters
# - p_state: the action input state to set
func set_action_input_state(p_state):
	action_state = p_state
	action_input_state_changed.emit()


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
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_VERB_CONFIRMATION)

	action_changed.emit()


# Clear the current action
func clear_current_action():
	set_current_action("")
	set_action_input_state(ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM)
	action_changed.emit()


# Clear the current tool
func clear_current_tool():
	current_tool = null
	current_target = null
	if action_state == ACTION_INPUT_STATE.AWAITING_VERB:
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM)
	elif action_state == ACTION_INPUT_STATE.AWAITING_TARGET_ITEM:
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_ITEM)


# Checks if the specified action is valid and returns the associated event;
# otherwise, we see if there's a "fallback" event and use that if necessary and,
# if not, we return no event as there's nothing to do.
#
# #### Parameters
#
# - action: Action to execute (defined in attached ESC file and in
#   action verbs UI) eg: arrived, use, look, pickup...
# - target: Target ESC object
# - combine_with: ESC object to combine with
#
# *Returns* the appropriate ESCGrammarStmts.Event to queue/run, or null if none can be found
# or there's a reason not to run an event.
func _get_event_to_queue(
	action: String,
	target: ESCObject,
	combine_with: ESCObject = null
) -> ESCGrammarStmts.Event:

	escoria.logger.info(
		self,
		"Checking if action '%s' on '%s' is valid..." % [action, target.global_id if target is ESCObject else target]
	)

	var event_to_return = null

	# If we're using an action which item requires to combine
	if target.node is ESCItem \
			and action in target.node.combine_when_selected_action_is_in:

		# Check if object is in inventory or is not required to be in inventory to be used
		if escoria.inventory_manager.inventory_has(target.global_id) or not target.node.use_from_inventory_only:
			# We check the element to use on
			if combine_with:
				var do_combine = true
				if combine_with.node is ESCItem \
						and combine_with.node.use_from_inventory_only\
						and not escoria.inventory_manager.inventory_has(
							combine_with.global_id
						):
					do_combine = false

				if do_combine:
#						var target_event = "%s %s" % [
#							action,
#							combine_with.global_id
#						]
#						var combine_with_event = "%s %s" % [
#							action,
#							target.global_id
#						]

					if _has_event_with_target(target.events, action, combine_with.global_id):
					#if target.events.has(target_event):
						#event_to_return = target.events[target_event]
						event_to_return = target.events[action]
					#elif combine_with.events.has(combine_with_event)\
					elif _has_event_with_target(combine_with.events, action, target.global_id)\
							and not combine_with.node.combine_is_one_way:

						#event_to_return = combine_with.events[combine_with_event]
						event_to_return = combine_with.events[action]
					else:
						# Check to see if there isn't a "fallback" action to
						# run before we declare this a failure.
						if escoria.action_default_script \
							and escoria.action_default_script.events.has(action):

							event_to_return = escoria.action_default_script.events[action]
						else:
							var errors = [
								"Attempted to execute action '%s' between item %s and item %s" % [
									action,
									target.global_id,
									combine_with.global_id
								],
								"Check that action ':%s %s' exists in the script of item '%s'" % [
									action,
									target.global_id,
									combine_with.global_id
								]
							]

							if combine_with.node.combine_is_one_way:
								errors.append(
									("Reason: %s's item interaction " + \
									"is one-way.") % combine_with.global_id
								)

							escoria.logger.warn(
								self,
								"Invalid action: " + str(errors)
							)
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
		else:
			escoria.logger.warn(
				self,
				"Invalid action on item: " +
				"Trying to run action '%s' on object %s, " %
				[
					action,
					target.node.global_id
				]
				+ "but item must be in inventory."
			)
	else:
		if _check_target_has_proper_action(target, action):
#			##SAVEGAME
#			if target.events[action].is_completed:
#				target.events[action].is_completed = false
#				target.events[action].from_statement_id = 0
			event_to_return = target.events[action]
		elif escoria.action_default_script \
			and escoria.action_default_script.events.has(action):

			# If there's a "fallback" action to run, return it
			event_to_return = escoria.action_default_script.events[action]
		else:
			escoria.logger.warn(
				self,
				"Invalid action: " +
					"Event for action '%s' on object '%s' not found." % [
						action,
						target.global_id
					]
			)

	return event_to_return


# Check to make sure `target` contains the specific `action`. If `target` has an entry for
# `action` that also requires a target itself (e.g. :use "wrench"), then we return false as
# combinations are handled elsewhere.
#
# #### Parameters
#
# - target: `ESCObject` whose events we are to check to see if `action` has a corresponding event
# - action: the action to check
#
# *Returns*
# True iff `target` has an event corresponding to `action` and that event doesn't itself require a target.
func _check_target_has_proper_action(target: ESCObject, action: String) -> bool:
	if target.events.has(action):
		if target.events[action].get_target():
			return false

		return true

	return false


# Determines whether the specified events dictionary contains an event with the
# specified event name and event target, e.g. :give "filled_out_form"
#
# #### Parameters
#
# - events_dict: dictionary with events to check
# - event_name: the event name to search for
# - event_target: the target for the specified event to check
#
# *Returns* true iff events_dict contains an event matching both event_name and
# event_target
func _has_event_with_target(events_dict: Dictionary, event_name: String, event_target: String):
	var event = events_dict.get(event_name)

	if event:
		return event.get_target_name() == event_target

	return false


# Runs the specified event.
#
# #### Parameters
#
# - event: the event to be run
#
# *Returns* the return code of the event once executed
func _run_event(event) -> int:
	escoria.event_manager.queue_event(event)

	var event_returned = await escoria.event_manager.event_finished

	while event_returned[1] != event.get_event_name():
		event_returned = await escoria.event_manager.event_finished

	clear_current_action()
	action_finished.emit()

	return event_returned[0]


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
	- validates the requested action
	- grabs the corresponding event for the action, if available
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

	# Don't interact after player movement towards object
	# (because object is inactive for example)
	var dont_interact = false

	# We need to have the new action input state BEFORE initiating the player
	# move so we determine now if the object clicked will require a combination
	# depending on the used action verb.
	var tool_just_set = _set_tool_and_action(obj, default_action)
	var need_combine = _check_item_needs_combine()

	# If the clicked item is not in the inventory and the current tool was not set,
	# then this is our first item, make it the tool.
	if (not escoria.inventory_manager.inventory_has(obj.global_id) and not current_tool) \
			or (current_tool and not need_combine):
		current_tool = obj
	# Else, if we have a tool and combination required, this is our second item,
	# make it the target.
	elif need_combine and not tool_just_set:
		current_target = obj

	# Update the action input state
	if action_state == ACTION_INPUT_STATE.AWAITING_TARGET_ITEM and current_target:
		set_action_input_state(ACTION_INPUT_STATE.COMPLETED)
	elif action_state == ACTION_INPUT_STATE.AWAITING_ITEM and \
			not need_combine:
		set_action_input_state(ACTION_INPUT_STATE.COMPLETED)
	elif action_state == ACTION_INPUT_STATE.AWAITING_ITEM and \
			need_combine and not tool_just_set:
		set_action_input_state(ACTION_INPUT_STATE.AWAITING_TARGET_ITEM)

	var event_to_queue: ESCGrammarStmts.Event = null


	# Manage exits first, actions last
	# If the clicked object is an exit and current action is "walk"/unset, we need to run the exit scene action.
	if obj.node.is_exit and current_action in ["", ACTION_WALK]:
		event_to_queue = _get_event_to_queue(ACTION_EXIT_SCENE, obj)
	# If the clicked object is not an exit, we check if the current action is "walk"/unset
	# If so, and if the object is not in the inventory, we need to run the arrived action.
	elif current_action in ["", ACTION_WALK] and not escoria.inventory_manager.inventory_has(obj.global_id):
		event_to_queue = _get_event_to_queue(ACTION_ARRIVED, obj)
	# If the current action is set and different from "walk"/unset, we need to check for combinations.
	elif not current_action in ["", ACTION_WALK]:
		# If clicked object needs a combination, and current target is set, then perform the combination.
		if need_combine and current_target:
			event_to_queue = _get_event_to_queue(current_action, current_tool, current_target)
		# If clicked object needs a combination then we need to wait for the target.
		elif need_combine:
			set_action_input_state(ACTION_INPUT_STATE.AWAITING_TARGET_ITEM)
			# If object is in inventory make it current tool.
			if escoria.inventory_manager.inventory_has(obj.global_id):
				current_tool = obj
		# If clicked object doesn't need a combination, then we simply run the action.
		else:
			event_to_queue = _get_event_to_queue(current_action, obj)

	# Get out of here if there's a specified action but an event couldn't be found.
	# Note that `event_to_queue` may still be null, but we do need to start the
	# player walking towards the destination.
	if current_action and not event_to_queue:
		clear_current_action()
		action_finished.emit()
		return

	var event_flags = event_to_queue.get_flags() if event_to_queue else 0

	if escoria.main.current_scene.player:
		var destination_position: Vector2 = escoria.main.current_scene.player \
				.global_position

		# If clicked object not in inventory, player walks towards it
		if not obj.node is ESCPlayer and \
			not escoria.inventory_manager.inventory_has(obj.global_id) and \
			not _telekinetic_applies_to(event_to_queue):
				var context = await _walk_towards_object(
					obj,
					event.position,
					event.double_click
				)

				# In case of an interrupted walk, we don't want to proceed.
				if context == null:
					return

				destination_position = context.target_position
				dont_interact = context.dont_interact_on_arrival

		var player_global_pos = escoria.main.current_scene.player.global_position
		var clicked_position = event.position

		# Using this instead of is_equal_approx due to
		# https://github.com/godotengine/godot/issues/65257
		if (player_global_pos - destination_position).length() > 1.0:
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
	if not dont_interact and event_to_queue:
		_run_event(event_to_queue)


func _telekinetic_applies_to(event: ESCGrammarStmts.Event) -> bool:
	if event.get_flags_with_conditions().has("TK"):
		var tk_flag_condition = event.get_flags_with_conditions().get("TK")

		if tk_flag_condition:
			var interpreter: ESCInterpreter = ESCInterpreterFactory.create_interpreter()

			var result = interpreter.look_up_global(tk_flag_condition.get_name())

			return false if result == null else bool(result)

		return true

	return false


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
		if not current_action in escoria.action_manager \
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
	var context: ESCWalkContext = await escoria.main.current_scene.player.arrived

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
		escoria.logger.trace(
			self,
			"Item %s is not active." % obj.global_id
		)
		object_is_actionable = false
	elif not obj.interactive:
		escoria.logger.trace(
			self,
			"Item %s is not interactive." % obj.global_id
		)
		object_is_actionable = false

	return object_is_actionable
