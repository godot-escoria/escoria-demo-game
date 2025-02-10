extends Control

@onready var screen_width = get_tree().get_root().get_viewport().size.x
@onready var screen_height = get_tree().get_root().get_viewport().size.y
var global_distance_to_clamp = 40: get = get_global_dist_clamp, set = set_global_dist_clamp

signal mouse_moved(position)
signal text_selected(text)

@export var path_to_richtextlabel: NodePath
const ONE_LINE_HEIGHT = 16
@export var max_width: int = 200
const MIN_HEIGHT = 30
const MAX_HEIGHT = 500

func _ready():
	assert(!path_to_richtextlabel.is_empty())
	$VBoxContainer/HBoxContainer/clamp_distance.text = str(global_distance_to_clamp)

	var button_group = ButtonGroup.new()
	$HBoxContainer2/foo.button_group = button_group
	$HBoxContainer2/foobar.button_group = button_group
	$HBoxContainer2/whatisit.button_group = button_group
	

	# Add a white TextureRect behind the RTL to see its actual size
	var texturerect_node = TextureRect.new()
	get_node(path_to_richtextlabel).add_child(texturerect_node)
	texturerect_node.texture = load("res://addons/escoria-core/game/assets/images/white.png")
	texturerect_node.expand = true
	texturerect_node.stretch_mode = TextureRect.STRETCH_TILE
	texturerect_node.size_flags_horizontal = SIZE_EXPAND_FILL
	texturerect_node.size_flags_vertical = SIZE_EXPAND_FILL
	texturerect_node.show_behind_parent = true
	texturerect_node.anchor_right = 1.0
	texturerect_node.anchor_bottom = 1.0
	move_child(get_node(path_to_richtextlabel), 1)

	update_line2d()
	_on_new_text_pressed()
	set_process_input(true)

func set_path_to_richtextlabel(path):
	path_to_richtextlabel = path


func _input(event):
	if event is InputEventMouseMotion:
		mouse_moved.emit(event.position)

func set_global_dist_clamp(d):
	global_distance_to_clamp = d
	update_line2d()

func get_global_dist_clamp():
	return global_distance_to_clamp

func update_line2d():
	$Line2D.clear_points()
	$Line2D.add_point(Vector2(global_distance_to_clamp, global_distance_to_clamp))
	$Line2D.add_point(Vector2(global_distance_to_clamp, screen_height - global_distance_to_clamp))
	$Line2D.add_point(Vector2(screen_width - global_distance_to_clamp, screen_height - global_distance_to_clamp))
	$Line2D.add_point(Vector2(screen_width - global_distance_to_clamp, global_distance_to_clamp))
	$Line2D.add_point(Vector2(global_distance_to_clamp, global_distance_to_clamp))


func _on_new_text_pressed():
	var pressed_button = $HBoxContainer2/foo.button_group.get_pressed_button()
	if pressed_button == null:
		return
	printt(pressed_button.name, pressed_button.text)
	text_selected.emit(pressed_button.text)


func tooltip_distance_to_edge_top(position: Vector2):
	return position.y

func tooltip_distance_to_edge_bottom(position: Vector2):
	return screen_height - position.y

func tooltip_distance_to_edge_left(position: Vector2):
	return position.x

func tooltip_distance_to_edge_right(position: Vector2):
	return screen_width - position.x

func _on_Control_mouse_moved(mouse_pos):
#	printt("mousepos", mouse_pos)
#	printt("label_container_pos", rect_position)

	#var corrected_position = _offset(new_pos)
	var corrected_position = mouse_pos

	# clamp TOP
	if tooltip_distance_to_edge_top(mouse_pos) <= global_distance_to_clamp:
		corrected_position.y = global_distance_to_clamp

	# clamp BOTTOM
	if tooltip_distance_to_edge_bottom(mouse_pos + get_node(path_to_richtextlabel).size) <= global_distance_to_clamp:
		corrected_position.y = screen_height - global_distance_to_clamp - get_node(path_to_richtextlabel).size.y

	# clamp LEFT
	if tooltip_distance_to_edge_left(mouse_pos - get_node(path_to_richtextlabel).size/2) <= global_distance_to_clamp:
		corrected_position.x = global_distance_to_clamp

	# clamp RIGHT
	if tooltip_distance_to_edge_right(mouse_pos + get_node(path_to_richtextlabel).size/2) <= global_distance_to_clamp:
		corrected_position.x = screen_width - global_distance_to_clamp - get_node(path_to_richtextlabel).size.x

	get_node(path_to_richtextlabel).anchor_right = 0.2
	get_node(path_to_richtextlabel).position = corrected_position


func _on_Control_text_selected(text):
	get_node(path_to_richtextlabel).text = "[color=red]" + text.replace("<br>", "\n") + "[/color]"
	update_size()

func _on_clamp_distance_text_changed(new_text):
	global_distance_to_clamp = int(new_text)
	update_line2d()


func _offset(position):
	var center_offset_x = size.x / 2
	var offset_y = 5

	position.x -= center_offset_x
	position.y += offset_y
	return position


func update_size():
	## RECT_SIZE ##
	var rtl_node = get_node(path_to_richtextlabel)
	var rtl_width = rtl_node.size.x
	var rtl_height = rtl_node.size.y
	var content_height = rtl_node.get_content_height()
	var nb_visible_characters = rtl_node.visible_characters
	var nb_visible_lines = rtl_node.get_visible_line_count()

	printt("BEFORE", "text_height", content_height, "rtl_height", rtl_node.size.y)

	# if text is too long and is wrapped
#	var nblines = float(rtl_node.get_content_height()) / float(ONE_LINE_HEIGHT)
	var nblines = nb_visible_lines
	if nblines >= 1:

		await get_tree().process_frame
		await get_tree().process_frame
		var text_height = rtl_node.get_content_height()
		if text_height > MAX_HEIGHT:
			text_height = MAX_HEIGHT
		if text_height <= MIN_HEIGHT:
			text_height = MIN_HEIGHT

		var parent_width = rtl_node.size.x

		# first, try to increase width until it goes above max_width
		while parent_width < max_width && float(text_height) / float(ONE_LINE_HEIGHT) > 1.0:
			rtl_node.size.x += 1
			parent_width = rtl_node.size.x


		rtl_node.size.y = text_height

		if rtl_node.size.x >= max_width:
			rtl_node.size.x = max_width

	## END RECT_SIZE ##
	rtl_node.anchor_top = 0.0
	rtl_node.anchor_right = 0.0
	rtl_node.anchor_bottom = 0.0
	rtl_node.anchor_left = 0.0
	printt("AFTER", "text_height", get_node(path_to_richtextlabel).get_content_height(), "rtl_height", rtl_node.size.y)
