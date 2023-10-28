extends ESCEvent
class_name l_door_exit_scene


func _init().(":exit_scene") -> void:
	pass


func run() -> int:
	var enable_automatic_transition = true
	escoria.room_manager.change_scene("res://game/rooms/room02/room02.tscn", enable_automatic_transition)

	var final_rc = ESCExecution.RC_OK
	var current_statement: ESCStatement = null
	emit_signal("finished", self, current_statement, final_rc)
	return final_rc
