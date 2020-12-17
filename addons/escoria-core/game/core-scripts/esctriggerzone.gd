tool
extends Area2D
class_name ESCTriggerZone

signal left_click_on_trigger
signal left_dblclick_on_trigger
signal right_click_on_trigger
signal mouse_enter_trigger
signal mouse_exit_trigger

func mouse_enter():
	emit_signal("mouse_enter_trigger", self)

func mouse_exit():
	emit_signal("mouse_exit_trigger", self)

func body_entered(body):
#	if body is esc_type.PLAYER:
#		if self.visible:
#			run_event("enter")
	pass

func body_exited(body):
#	if body is esc_type.PLAYER:
#		if self.visible:
#			run_event("exit")
	pass




