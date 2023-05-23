extends CanvasLayer

onready var list = $VBoxContainer/hover_stack

func update() -> void:
	for e in list.get_children():
		list.remove_child(e)
		e.queue_free()
	if escoria.inputs_manager.hover_stack.empty():
		return
	for e in escoria.inputs_manager.hover_stack.get_all():
		var l = Label.new()
		l.text = e.global_id
		list.add_child(l)
