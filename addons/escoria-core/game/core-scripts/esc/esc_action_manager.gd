# Manages currently carried out actions
extends Object
class_name ESCActionManager


# The current action was changed
signal action_changed


# Current verb used
var current_action: String = "" setget set_current_action

# Current tool (ESCItem/ESCInventoryItem) used
var current_tool: ESCObject


# Set the current action
func set_current_action(action: String):
	if action != current_action:
		clear_current_tool()
		
	current_action = action
	emit_signal("action_changed")


# Clear the current action
func clear_current_action():
	set_current_action("")


# Clear the current tool
func clear_current_tool():
	current_tool = null


# Activates the action for given params
#
# #### Parameters
#
# - action String Action to execute (defined in attached ESC file and in
#   action verbs UI) eg: arrived, use, look, pickup...
# - target: Target ESC object
# - combine_with: ESC object to combine with
func activate(
	action: String, 
	target: ESCObject, 
	combine_with: ESCObject = null
) -> int:
	escoria.logger.info("Activated action %s on %s" % [action, target])
	
	# If we're using an action which item requires to combine
	if target.node is ESCItem\
			and action in target.node.combine_if_action_used_among:
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
								escoria.action_manager\
										.clear_current_action()
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
								escoria.action_manager\
										.clear_current_action()
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
									"Reason: %s's item interaction " +\
									"is one-way." % combine_with.global_id
								)
							escoria.logger.report_warnings(
								"ESCActionManager.activate: Invalid action", 
								errors
							)
								
							return ESCExecution.RC_ERROR
					else:
						escoria.logger.report_warnings(
							"ESCActionManager.activate: Invalid action on item", 
							[
								"Trying to combine object %s with %s, "+
								"but %s is not in inventory." % [
									target.global_id,
									combine_with.global_id,
									combine_with.global_id
								]
							]
						)	
						return ESCExecution.RC_ERROR
				else:
					# We're missing a target here. 
					# Tell the Label to add a conjunction and wait for another 
					# click to add the target to p_param. Until then, return
					current_tool = target
					return ESCExecution.RC_OK
			else: 
				escoria.logger.report_warnings(
					"ESCActionManager.activate: Invalid action on item", 
					[
						"Trying to run %s on object %s, " %
						[
							action,
							target.node.global_id
						]
						+ "but item must be in inventory."
					]
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
			escoria.action_manager.clear_current_action()
		return event_returned[0]
	else:
		escoria.logger.report_warnings(
			"ESCActionManager.activate: Invalid action", 
			[
				"Event for action %s on object %s not found." % [
					action,
					target.global_id
				]
			]
		)
		return ESCExecution.RC_ERROR
