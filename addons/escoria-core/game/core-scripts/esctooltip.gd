tool
extends RichTextLabel
class_name ESCTooltip

func get_class():
	return "ESCTooltip"


# Infinitive verb
var current_action : String
# Target item/hotspot
var current_target : String setget set_target
# Preposition: on, with...
var current_prep : String = "with"
# Target 2 item/hotspot
var current_target2 : String
# True if tooltip is waiting for a click on second target (use x with y)
var waiting_for_target2 = false

export(Color) var color setget set_color
export(Vector2) var offset_from_cursor = Vector2(10,0)

export(bool) var debug_mode = false setget set_debug_mode
var debug_texturerect_node : TextureRect

const MAX_WIDTH = 200
const MIN_HEIGHT = 30
const MAX_HEIGHT = 500
const ONE_LINE_HEIGHT = 16



func _ready():
	escoria.call_deferred("register_object", self)
	escoria.esc_runner.connect("action_changed", self, "on_action_selected")
	

func set_color(p_color : Color):
	color = p_color
	update_tooltip_text()


func set_debug_mode(p_debug_mode : bool):
	debug_mode = p_debug_mode
	if debug_mode:
		# Add a white TextureRect behind the RTL to see its actual size
		debug_texturerect_node = TextureRect.new()
		add_child(debug_texturerect_node)
		debug_texturerect_node.texture = load("res://addons/escoria-core/game/assets/images/white.png")
		debug_texturerect_node.expand = true
		debug_texturerect_node.stretch_mode = TextureRect.STRETCH_TILE
		debug_texturerect_node.size_flags_horizontal = SIZE_EXPAND_FILL
		debug_texturerect_node.size_flags_vertical = SIZE_EXPAND_FILL
		debug_texturerect_node.show_behind_parent = true
		debug_texturerect_node.anchor_right = 1.0
		debug_texturerect_node.anchor_bottom = 1.0
		debug_texturerect_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		move_child(debug_texturerect_node, 2)
	else:
		remove_child(debug_texturerect_node)
	

func on_action_selected() -> void:
	current_action = escoria.esc_runner.current_action
	update_tooltip_text()


func set_target(target : String, needs_second_target : bool = false) -> void:
	current_target = target
	if needs_second_target:
		waiting_for_target2 = true
	update_tooltip_text()


func set_target2(target2 : String) -> void:
	current_target2 = target2
	update_tooltip_text()



func update_tooltip_text():
	"""
	Overriden method. Should not be called directly.
	"""
	pass



func update_size():
	## RECT_SIZE ##
	var rtl_width = rect_size.x
	var rtl_height = rect_size.y
	var content_height = get_content_height()
	var nb_visible_characters = visible_characters
	var nb_visible_lines = get_visible_line_count()
	
	printt("BEFORE", "text_height", content_height, "rtl_height", rect_size.y)
	
	# if text is too long and is wrapped
#	var nblines = float(get_content_height()) / float(ONE_LINE_HEIGHT)
	var nblines = nb_visible_lines
	if nblines >= 1:
		
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		var text_height = get_content_height()
		if text_height > MAX_HEIGHT:
			text_height = MAX_HEIGHT
		if text_height <= MIN_HEIGHT:
			text_height = MIN_HEIGHT
		
		var parent_width = rect_size.x
		
		# first, try to increase width until it goes above max_width
		while parent_width < MAX_WIDTH && float(text_height) / float(ONE_LINE_HEIGHT) > 1.0:
			rect_size.x += 1
			parent_width = rect_size.x
		
		
		rect_size.y = text_height
		
		if rect_size.x >= MAX_WIDTH:
			rect_size.x = MAX_WIDTH
		
	## END RECT_SIZE ##
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	anchor_left = 0.0
	printt("AFTER", "text_height", get_content_height(), "rtl_height", rect_size.y)


func _offset(position):
	var center_offset_x = rect_size.x / 2
	var offset_y = 5
	
	position.x -= center_offset_x
	position.y += offset_y
	
	return position


func tooltip_distance_to_edge_top(position : Vector2):
	return position.y

func tooltip_distance_to_edge_bottom(position: Vector2):
	return escoria.game_size.y - position.y

func tooltip_distance_to_edge_left(position : Vector2):
	return position.x

func tooltip_distance_to_edge_right(position : Vector2):
	return escoria.game_size.x - position.x
