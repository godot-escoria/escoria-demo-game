# GdUnit generated TestSuite
class_name ESCNewGameStateTest
extends GdUnitTestSuite


func test_new_game_runtime_reset_clears_transient_input_state() -> void:
	var escoria_node = escoria.get_escoria()
	var tool_node := ESCItem.new()
	tool_node.global_id = "test_tool"
	var tool_object := ESCObject.new(tool_node.global_id, tool_node)
	var hovered_item := ESCItem.new()
	hovered_item.global_id = "test_hovered_item"
	hovered_item.z_index = 1

	escoria.action_manager.set_current_action("use")
	escoria.action_manager.current_tool = tool_object
	escoria.action_manager.current_target = tool_object
	escoria.action_manager.set_action_input_state(
		ESCActionManager.ActionInputState.AWAITING_TARGET_ITEM
	)
	escoria.inputs_manager.hover_stack.hover_stack.append(hovered_item)
	escoria.inputs_manager.hotspot_focused = "test_hotspot"
	escoria.inputs_manager.input_mode = escoria.inputs_manager.INPUT_NONE

	escoria_node._reset_new_game_runtime_state()

	assert_str(escoria.action_manager.current_action).is_equal("")
	assert_object(escoria.action_manager.current_tool).is_null()
	assert_object(escoria.action_manager.current_target).is_null()
	assert_int(escoria.action_manager.action_state).is_equal(
		ESCActionManager.ActionInputState.AWAITING_VERB_OR_ITEM
	)
	assert_bool(escoria.inputs_manager.hover_stack.is_empty()).is_true()
	assert_str(escoria.inputs_manager.hotspot_focused).is_equal("")
	assert_int(escoria.inputs_manager.input_mode).is_equal(escoria.inputs_manager.INPUT_ALL)

	tool_node.free()
	hovered_item.free()
