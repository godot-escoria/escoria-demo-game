extends RichTextLabel

# Infinitive verb
var current_action : String
# Target item/hotspot
var current_target : String
# Preposition: on, with...
var current_prep : String = "with"
# Target 2 item/hotspot
var current_target2 : String

var waiting_for_target2 = false

func _ready():
	escoria.esc_runner.connect("action_changed", self, "on_action_selected")


func on_action_selected() -> void:
	current_action = escoria.esc_runner.current_action
	update_tooltip_text()

#func element_focused(element_id : String) -> void:
#	printt("action_target_tooltip.gd:on_element_focused()", "Element focused: ", element_id)
#
#	if element_id == "":
#		set_target("")
#		return
#
#	var object = escoria.esc_runner.get_object(element_id)
#
#	if object == null or !is_instance_valid(object):
#		escoria.report_warnings("action_target_tooltip.gd:on_element_focused()",
#			["Object exists but is not loaded for id " + element_id])
#		set_target(element_id)
#		return
#
#	if !escoria.esc_runner.get_interactive(element_id) and !object is ESCInventoryItem:
#		set_target("")
#		return
#
#	var wait_for_target = false
#	if object is ESCItem or object is ESCInventoryItem:
#		if current_action in object.combine_if_action_used_among:
#			wait_for_target = true
#
#	set_target(object.tooltip_name, wait_for_target)


func set_target(target : String, needs_second_target : bool = false) -> void:
	current_target = target
	if needs_second_target:
		waiting_for_target2 = true
	
	update_tooltip_text()


func set_target2(target2 : String) -> void:
	current_target2 = target2
	update_tooltip_text()


func update_tooltip_text():
	bbcode_text = "[center]"
	
	if !current_action.empty():
		bbcode_text += current_action
		bbcode_text += "\t"
		
	bbcode_text += current_target
	
	if waiting_for_target2 and current_target2.empty():
		bbcode_text += "\t"
		bbcode_text += current_prep
		
	if !current_target2.empty():
		bbcode_text += "\t"
		bbcode_text += current_prep
		bbcode_text += "\t"
		bbcode_text += current_target2
	
	bbcode_text += "[/center]"
