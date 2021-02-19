extends TextureButton
class_name ESCInventoryItem

func get_class():
	return "ESCInventoryItem"

export(String) var global_id
#export(String, FILE, "*.esc") var esc_script

signal mouse_left_inventory_item(item_id)
signal mouse_right_inventory_item(item_id)
signal mouse_double_left_inventory_item(item_id)
signal inventory_item_focused(item_id)
signal inventory_item_unfocused()


func _ready():
	connect("gui_input", self, "_on_inventory_item_gui_input")
	connect("mouse_entered", self, "_on_inventory_item_mouse_enter")
	connect("mouse_exited", self, "_on_inventory_item_mouse_exit")

func _on_inventory_item_gui_input(event : InputEvent):
	if event.is_action_pressed("switch_action_verb"):
		if event.button_index == BUTTON_WHEEL_UP:
			escoria.inputs_manager._on_mousewheel_action(-1)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			escoria.inputs_manager._on_mousewheel_action(1)
	if event is InputEventMouseButton:
#		var p = get_global_mouse_position()
		if event.doubleclick:
			if event.button_index == BUTTON_LEFT:
				emit_signal("mouse_double_left_inventory_item", global_id, event)
		else:
			if event.is_pressed():
				if event.button_index == BUTTON_LEFT:
					emit_signal("mouse_left_inventory_item", global_id, event)
				if event.button_index == BUTTON_RIGHT:
					emit_signal("mouse_right_inventory_item", global_id, event)
	
func _on_inventory_item_mouse_enter():
	# Notify UI that item is focused (room.game.ui.Label UI)
	emit_signal("inventory_item_focused", global_id)

func _on_inventory_item_mouse_exit():
	# Notify UI that item is unfocused (room.game.ui.Label UI)
	emit_signal("inventory_item_unfocused")
