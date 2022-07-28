tool
extends WindowDialog


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

const LAST_PAGE = 15

export var current_page = 1


func help_on_prev_button_pressed() -> void:
	current_page -= 1
	if current_page < 1:
		current_page = 1
	show_page()


func help_on_next_button_pressed() -> void:
	current_page += 1
	if current_page > LAST_PAGE:
		current_page = LAST_PAGE
	show_page()


func show_page() -> void:
	for loop in get_tree().get_nodes_in_group("masks"):
		loop.visible = false
	for loop in get_tree().get_nodes_in_group("pagetext"):
		loop.visible = false

	$masks/leftall.visible = true
	$masks/middleall.visible = true
	$masks/rightall.visible = true

	get_node("masks").get_node("page%s" % current_page).visible = true
	get_node("text").get_node("page%s" % current_page).visible = true

	match current_page:
		2:	$masks/leftall.visible = false
		3:	$masks/rightall.visible = false
		4:	$masks/leftall.visible = false
		5:	$masks/leftall.visible = false
		6:	$masks/leftall.visible = false
		7:	$masks/leftall.visible = false
		8:	$masks/middleall.visible = false
		9:	$masks/middleall.visible = false
		10:	$masks/middleall.visible = false
		11:	$masks/rightall.visible = false
		12:	$masks/rightall.visible = false
		13:	$masks/rightall.visible = false
		14:	$masks/rightall.visible = false


