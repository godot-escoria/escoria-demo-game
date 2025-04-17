@tool
# Outstanding proposed features
# v1.1 features
# * Have the editor kick in when an ESCPlayer is selected, i.e. "load/edit"
# * Add a settings page (if there's enough features to warrant it). This would have the path the scene gets written to,  default angles for each direction so the developer can change them from the default 90s / 45s they are now, whether the ESCPlayer is click-through, errr can't think of anything else.
# * Redo the Escoria tutorial to use the plugin.

extends Control

const METADATA_ANIM_NAME = "anim_name"
const METADATA_SPRITESHEET_SOURCE_FILE = "spritesheet_source_file"
const METADATA_SPRITESHEET_FRAMES_HORIZ = "spritesheet_frames_horiz"
const METADATA_SPRITESHEET_FRAMES_VERT = "spritesheet_frames_vert"
const METADATA_SPRITESHEET_FIRST_FRAME = "spritesheet_first_frame"
const METADATA_SPRITESHEET_LAST_FRAME = "spritesheet_last_frame"
const METADATA_SPEED = "speed"
const METADATA_IS_MIRROR = "is_mirror"

const DIR_UP = "up"
const DIR_UP_RIGHT = "upright"
const DIR_RIGHT = "right"
const DIR_DOWN_RIGHT = "downright"
const DIR_DOWN = "down"
const DIR_DOWN_LEFT = "downleft"
const DIR_LEFT = "left"
const DIR_UP_LEFT = "upleft"

const DIR_LIST_8 = [DIR_UP, DIR_UP_RIGHT, DIR_RIGHT, DIR_DOWN_RIGHT, DIR_DOWN, DIR_DOWN_LEFT, \
	DIR_LEFT, DIR_UP_LEFT]
const DIR_LIST_4 = [DIR_UP, DIR_RIGHT, DIR_DOWN, DIR_LEFT]
const DIR_LIST_2 = [DIR_RIGHT, DIR_LEFT]
const DIR_LIST_1 = [DIR_DOWN]

const TYPE_WALK = "walk"
const TYPE_TALK = "talk"
const TYPE_IDLE = "idle"

const ANIM_IN_PROGRESS = "in_progress"

const ANIMATION_SPEED_LABEL = "Animation speed"

# Make the code more readable by shortening node references using constants
const NAME_NODE            = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/node_name/MarginContainer2/GridContainer"
const DIR_COUNT_NODE       = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/directions/HBoxContainer"
const CHAR_TYPE_NODE       = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/charactertype/HBoxContainer"
const ANIM_TYPE_NODE       = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer"
const MIRROR_NODE          = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer2/HBoxContainer/MarginContainer3/mirror_checkbox"
const ARROWS_NODE          = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer2/HBoxContainer/MarginContainer2/GridContainer"
const PREVIEW_NODE         = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer2/preview/MarginContainer"
const PREVIEW_BGRND_NODE   = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer2/preview/anim_preview_background"
const ANIM_CONTROLS_NODE   = "VBoxContainer/HBoxContainer/spritesheet_controls/VBoxContainer/spritesheet_details_container/GridContainer"
const STORE_ANIM_NODE      = "VBoxContainer/HBoxContainer/spritesheet_controls/VBoxContainer/store_anim"
const SCROLL_VBOX_NODE     = "VBoxContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/"
const SCROLL_CTRL_NODE     = "VBoxContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/spritesheet_scroll_container/control"
const NO_SPRITESHEET_NODE  = "VBoxContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/spritesheet_scroll_container/control/MarginContainer/no_spritesheet_found_sprite"
const CURRENT_SHEET_NODE   = "VBoxContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/zoom_current/MarginContainer2/current_spritesheet_label"
const ZOOM_LABEL_NODE      = "VBoxContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/zoom_scroll/zoom_label"
const ZOOM_SCROLL_NODE     = "VBoxContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/zoom_scroll/MarginContainer/zoom_scrollbar"
const CHARACTER_PATH_NODE  = "VBoxContainer/HBoxContainer/configuration/VBoxContainer/node_name/MarginContainer2/GridContainer/character_path"
const GENERIC_ERROR_NODE   = "InformationWindows/generic_error_window"
const UNSTORED_CHANGE_NODE = "InformationWindows/unstored_changes_window"
const UNSTORED_ANIMTYPE_CHANGE_NODE = "InformationWindows/unstored_changes_window_anim_change"
const EXPORT_PROGRESS_NODE = "InformationWindows/export_progress"
const PROGRESS_LABEL_NODE  = "InformationWindows/export_progress/progress_label"
const EXPORT_COMPLETE_NODE = "InformationWindows/export_complete"
const FILE_DIALOG_NODE     = "ImageFileDialog"
const CHARACTER_FILE_NODE  = "CharacterPathFileDialog"
const CONFIG_FILE          = "escoria-wizard.conf"


# Test flag - set to true to load test data.
var test_mode: bool = true

# The currently loaded spritesheet image
var source_image: Image

# The current size of each animation frame (the spritesheet is broken into squares of this size.
var frame_size: Vector2

# The current spritesheet zoom level.
var zoom_value: float = 1

# The speed of the animation being previewed in frames-per-second.
var current_animation_speed: int = 5

# The animation direction currently being edited
var direction_selected: String

# This is the animation direction that has been clicked on by the user.
# Once it has been confirmed that there are no unstored changes to the current animation,
# the requested direction will become the "direction_selected".
var direction_requested: String

# The animation type currently being edited
var animation_type_selected: String

# This is the animation ty[e that has been clicked on by the user.
# Once it has been confirmed that there are no unstored changes to the current animation,
# the requested type will become the "animation_type_selected".
var animation_type_requested: String

# This is the array that stores the data for each animation.
var anim_metadata = []

# Track the page showing in the help window
var help_window_page = 1

# Array to track frame settings so if you do an illegal action (like changing the last sprite frame
# prior to a spritesheet being loaded) the value can be reset
var spritesheet_settings = [1, 1, 0, 0]

# To stop errors flagging when you change to a mirrored direction
var currently_changing_direction: bool = false

# Whether all changes are automatically 'saved' or need manual confirmation before storing
var autostore: bool = false

# Needed due to the yield method used for export to pass back the largest sprite used
# for the character. This will determine the collision shape size.
var export_largest_sprite: Vector2


func _ready() -> void:
	load_settings()
	character_creator_reset()
	$InformationWindows/help_window.current_page = 1

	if test_mode:
		setup_test_data()


func character_creator_reset() -> void:
	# Disconnect all the signals to stop program logic firing during setup
	disconnect_selector_signals()

	get_node(NAME_NODE).get_node("node_name").text = "replace_me"
	get_node(NAME_NODE).get_node("global_id").text = ""
	get_node(DIR_COUNT_NODE).get_node("four_directions").button_pressed = true

	# For unknown reasons the above doesn't cause the trigger to fire so manual steps required
	get_node(DIR_COUNT_NODE).get_node("eight_directions").button_pressed = false
	get_node(DIR_COUNT_NODE).get_node("two_directions").button_pressed = false
	get_node(DIR_COUNT_NODE).get_node("one_direction").button_pressed = false

	get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed = true
	animation_type_selected = "walk"

	# For unknown reasons the above doesn't cause the trigger to fire so manual steps required
	if get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed:
		get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed = false

	if get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed:
		get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed = false

	get_node(NO_SPRITESHEET_NODE).visible = true
	zoom_value = 1
	get_node(ZOOM_SCROLL_NODE).value = zoom_value
	get_node(ZOOM_LABEL_NODE).text = "Zoom: %sx" % str(zoom_value)
	get_node(ANIM_CONTROLS_NODE).get_node("original_size_label").text = "Source sprite size: (0, 0)"
	get_node(ANIM_CONTROLS_NODE).get_node("frame_size_label").text = "Frame size: (0, 0)"
	get_node(PREVIEW_NODE).get_node("anim_preview_sprite").animation = ANIM_IN_PROGRESS

	preview_hide()

	get_node(STORE_ANIM_NODE).visible = false

	create_empty_animations()

	direction_selected = DIR_UP
	activate_direction(direction_selected)

	reset_arrow_colours()

	# Reset GUI controls to initial values
	get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = spritesheet_settings[0]
	get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = spritesheet_settings[1]
	get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = spritesheet_settings[2]
	get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = spritesheet_settings[3]
	get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").value = current_animation_speed
	get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_label").text = "%s: 5 FPS" % ANIMATION_SPEED_LABEL
	get_node(CURRENT_SHEET_NODE).text="No spritesheet loaded."
	# Connect all the signals now the base settings are configured to stop program logic firing during setup
	reset_frame_outlines()

	# Make sure help window doesn't swallow mouse input
	$InformationWindows.visible = false
	autostore = $VBoxContainer/HBoxContainer/configuration/VBoxContainer/animation/autosave/HBoxContainer/AutoStoreCheckBox.button_pressed
	connect_selector_signals()


func connect_selector_signals() -> void:
	get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").connect("value_changed", Callable(self, "controls_on_h_frames_spin_box_value_changed"))
	get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").connect("value_changed", Callable(self, "controls_on_v_frames_spin_box_value_changed"))
	get_node(ANIM_CONTROLS_NODE).get_node("start_frame").connect("value_changed", Callable(self, "controls_on_start_frame_value_changed"))
	get_node(ANIM_CONTROLS_NODE).get_node("end_frame").connect("value_changed", Callable(self, "controls_on_end_frame_value_changed"))
	get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").connect("value_changed", Callable(self, "controls_on_anim_speed_scroll_bar_value_changed"))


func disconnect_selector_signals() -> void:
	if get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").is_connected("value_changed", Callable(self, "controls_on_h_frames_spin_box_value_changed")):
		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").disconnect("value_changed", Callable(self, "controls_on_h_frames_spin_box_value_changed"))

	if get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").is_connected("value_changed", Callable(self, "controls_on_v_frames_spin_box_value_changed")):
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").disconnect("value_changed", Callable(self, "controls_on_v_frames_spin_box_value_changed"))

	if get_node(ANIM_CONTROLS_NODE).get_node("start_frame").is_connected("value_changed", Callable(self, "controls_on_start_frame_value_changed")):
		get_node(ANIM_CONTROLS_NODE).get_node("start_frame").disconnect("value_changed", Callable(self, "controls_on_start_frame_value_changed"))

	if get_node(ANIM_CONTROLS_NODE).get_node("end_frame").is_connected("value_changed", Callable(self, "controls_on_end_frame_value_changed")):
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").disconnect("value_changed", Callable(self, "controls_on_end_frame_value_changed"))

	if get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").is_connected("value_changed", Callable(self, "controls_on_anim_speed_scroll_bar_value_changed")):
		get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").disconnect("value_changed", Callable(self, "controls_on_anim_speed_scroll_bar_value_changed"))


func reset_frame_outlines() -> void:
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").zoom_factor = .01
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").total_num_columns = 1
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").total_num_rows = 1
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").start_cell = 0
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").end_cell = 0
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").cell_size = Vector2(1,1)
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").queue_redraw()


func calc_sprite_size() -> void:
	var source_size = source_image.get_size()
	var horiz_size = int(source_size.x / get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value)
	var vert_size = int(source_size.y / get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value)

	frame_size = Vector2(horiz_size, vert_size)

	get_node(ANIM_CONTROLS_NODE).get_node("original_size_label").text = "Source sprite size: %s" % source_size
	get_node(ANIM_CONTROLS_NODE).get_node("frame_size_label").text = "Frame size: %s" % frame_size


# Load test data - primarily for testing export, but also for testing general functionality.
# Different spritesheets, mirroring settings, frame counts, and speeds are used deliberately.
func setup_test_data() -> void:
#	load_spritesheet("res://addons/escoria-wizard/graphics/mark-animtest.png")
#	# Up, right, down, left, up/r, down/r, down/l, up/l
#	var start_frames = [15, 10, 7, 10, 12, 14, 1, 14, 12, 3, 1, 1]
#	var end_frames = [17, 14, 9, 14, 13, 18, 3, 18, 12, 3, 1, 22]
#	var mirrored = [0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0,]
#	var sourcefile = [0, 0, 0, 0, 2, 2, 1, 2, 2, 0, 0, 0]
#	var fps = [3, 3, 1, 3, 3, 3, 1, 3, 3, 3, 1, 3]
#
#	for loop in range(12):	# 12 for a 4 direction character, 24 for an 8 direction character
#		if sourcefile[loop] == 0:
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_SOURCE_FILE] = "res://addons/escoria-wizard/graphics/mark-animtest.png"
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_HORIZ] = 8
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_VERT] = 3
#		elif sourcefile[loop] == 1:
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_SOURCE_FILE] = "res://game/characters/mark/png/mark_talk_down.png"
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_HORIZ] = 3
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_VERT] = 1
#		else:
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_SOURCE_FILE] = "res://game/characters/mark/png/markjester_talk.png"
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_HORIZ] = 21
#			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_VERT] = 1
#
#		anim_metadata[loop * 2][METADATA_SPRITESHEET_FIRST_FRAME] = start_frames[loop]
#		anim_metadata[loop * 2][METADATA_SPRITESHEET_LAST_FRAME] = end_frames[loop]
#		anim_metadata[loop * 2][METADATA_SPEED] = fps[loop]
#
#		anim_metadata[loop * 2][METADATA_IS_MIRROR] = mirrored[loop] != 0
#
#	get_node(NO_SPRITESHEET_NODE).visible = false
#
#	reset_arrow_colours()
	# Up, right, down, left, up/r, down/r, down/l, up/l
	var spritebase:String="addons/escoria-wizard/graphics/robot"
#	load_spritesheet("" + $spritepath + "/walk_up.png")
	var start_frames = [1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1, 5,6,4,3,1,2,4,6]
	var end_frames = [16,16,16,16,16,16,16,16, 53,53,53,53,53,53,53,53, 5,6,4,3,1,2,4,6]
	var mirrored = [0,0,0,0,0,0,1,1, 0,0,0,0,0,0,1,1, 0,1,1,0,0,0,0,0]
	var frames_h = [16,16,16,16,16,16,16,16, 14,14,14,14,14,14,14,14, 6,6,6,6,6,6,6,6]
	var frames_v = [1,1,1,1,1,1,1,1, 4,4,4,4,4,4,4,4, 1,1,1,1,1,1,1,1]

	anim_metadata[0][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/walk_up.png"
	anim_metadata[1][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/walk_upright.png"
	anim_metadata[2][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/walk_right.png"
	anim_metadata[3][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/walk_downright.png"
	anim_metadata[4][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/walk_down.png"
	anim_metadata[5][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/walk_downleft.png"
	anim_metadata[6][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/walk_right.png"
	anim_metadata[7][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/walk_upright.png"

	anim_metadata[8][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/talk_up.png"
	anim_metadata[9][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/talk_upright.png"
	anim_metadata[10][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/talk_right.png"
	anim_metadata[11][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/talk_downright.png"
	anim_metadata[12][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/talk_down.png"
	anim_metadata[13][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/talk_downleft.png"
	anim_metadata[14][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/talk_right.png"
	anim_metadata[15][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/talk_upright.png"

	anim_metadata[16][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/idle_all.png"
	anim_metadata[17][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/idle_all.png"
	anim_metadata[18][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/idle_all.png"
	anim_metadata[19][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/idle_all.png"
	anim_metadata[20][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/idle_all.png"
	anim_metadata[21][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/idle_all.png"
	anim_metadata[22][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/idle_all.png"
	anim_metadata[23][METADATA_SPRITESHEET_SOURCE_FILE] = spritebase + "/idle_all.png"

	for loop in range(24):
		anim_metadata[loop][METADATA_SPRITESHEET_FIRST_FRAME] = start_frames[loop]
		anim_metadata[loop][METADATA_SPRITESHEET_LAST_FRAME] = end_frames[loop]
		anim_metadata[loop][METADATA_SPEED] = 24
		anim_metadata[loop][METADATA_IS_MIRROR] = mirrored[loop] != 0
		anim_metadata[loop][METADATA_SPRITESHEET_FRAMES_HORIZ] = frames_h[loop]
		anim_metadata[loop][METADATA_SPRITESHEET_FRAMES_VERT] = frames_v[loop]

	get_node(NO_SPRITESHEET_NODE).visible = false
	get_node(DIR_COUNT_NODE).get_node("eight_directions").button_pressed = true
	for loop in ["four_directions", "two_directions", "one_direction"]:
		get_node(DIR_COUNT_NODE).get_node(loop).button_pressed = false
	reset_arrow_colours()


# Animations are stored as metadata in an array. This creates the initial empty array.
# The preview animation ("in_progress") is the only sprite animation created prior to the final export.
func create_empty_animations() -> void:
	var sframes = SpriteFrames.new()

	var metadata_dict = {
		METADATA_ANIM_NAME: "tbc",
		METADATA_SPRITESHEET_SOURCE_FILE: "tbc",
		METADATA_SPRITESHEET_FRAMES_HORIZ: -1,
		METADATA_SPRITESHEET_FRAMES_VERT: -1,
		METADATA_SPRITESHEET_FIRST_FRAME: 0,
		METADATA_SPRITESHEET_LAST_FRAME: 0,
		METADATA_SPEED: 30,
		METADATA_IS_MIRROR: false
	}

	var local_dict

	anim_metadata.clear()

	for typeloop in [TYPE_WALK, TYPE_TALK, TYPE_IDLE]:
		for dirloop in DIR_LIST_8:
			local_dict = metadata_dict.duplicate()
			local_dict[METADATA_ANIM_NAME] = "%s_%s" % [typeloop, dirloop]
			anim_metadata.append(local_dict)

	sframes.add_animation(ANIM_IN_PROGRESS)

	get_node(PREVIEW_NODE).get_node("anim_preview_sprite").sprite_frames = sframes


# Loads a spritesheet and calculates the size of each sprite frame if loading a spritesheet
# to show a previously stored animation.
func load_spritesheet(file_to_load, read_settings_from_metadata: bool = false, metadata_frame: int = 0) -> void:
	if source_image == null:
		source_image = Image.new()

	var errorval = source_image.load(file_to_load)

	assert(not errorval, "Error loading file %s" % str(file_to_load))

	var texture = ImageTexture.create_from_image(source_image)
	#texture.set_flags(2) # Godot 4 no longer allows for direct setting of "repetition" or other flags in textures

	get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").texture = texture

	frame_size = source_image.get_size()

	if read_settings_from_metadata:
		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = anim_metadata[metadata_frame][METADATA_SPRITESHEET_FRAMES_HORIZ]
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = anim_metadata[metadata_frame][METADATA_SPRITESHEET_FRAMES_VERT]
	else:
		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = 1
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = 1
		get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = 1
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = 1

	calc_sprite_size()

	get_node(CURRENT_SHEET_NODE).text = file_to_load
	draw_frame_outlines()
	set_zoom_scale_automatically(source_image.get_size())

	# Make scroll bars appear if necessary
	get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").custom_minimum_size = source_image.get_size() * zoom_value


# spritesheet is loaded.
func set_zoom_scale_automatically(spritesheet_size) -> void:

	var available_space = get_node(SCROLL_VBOX_NODE).get_node("spritesheet_scroll_container").size

	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	var spritesheet_scale = Vector2.ONE
	spritesheet_scale.x = available_space.x / spritesheet_size.x
	spritesheet_scale.y = available_space.y / spritesheet_size.y
	var blah = Vector2.ONE
	blah.x = spritesheet_size.x / available_space.x
	blah.y = spritesheet_size.y / available_space.y

	var newscale = 0.0
	if spritesheet_scale.y > spritesheet_scale.x:
		# Round to 1 decimal place
		newscale = (int(spritesheet_scale.x * 10.0)) / 10.0
	else:
		# Round to 1 decimal place
		newscale = (int(spritesheet_scale.y * 10.0)) / 10.0
	if newscale < 0.1:
		newscale = 0.1
	if newscale > 5:
		newscale = 5
	get_node(ZOOM_SCROLL_NODE).value = newscale


# Draws an outline on the spritesheet to show which frames are included in the current animation
func draw_frame_outlines() -> void:
	check_frame_limits()
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").zoom_factor = zoom_value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").total_num_columns = get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").total_num_rows = get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").start_cell = get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").end_cell = get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").cell_size = frame_size
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").queue_redraw()


# When given a frame number, this calculates the pixel coordinates that frame in the spritesheet
# based on the number of horizontal/vertical frames configured for this spritesheet
func calc_frame_coords(Frame: int) -> Vector2:
	var column = (Frame - 1) % int(get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value) * frame_size.x
	var row = int((Frame - 1) / get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value) * frame_size.y
	return Vector2(column, row)


# Updates the animation metadata to store the changed / new settings for a particular animation
func store_animation(animation_to_store: String) -> void:
	var texture
	var rect_location
	var frame_being_copied = Image.new()
	var frame_counter: int = 0

	var metadata_dict = {
		METADATA_ANIM_NAME: animation_to_store,
		METADATA_SPRITESHEET_SOURCE_FILE: get_node(CURRENT_SHEET_NODE).text,
		METADATA_SPRITESHEET_FRAMES_HORIZ: get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value,
		METADATA_SPRITESHEET_FRAMES_VERT: get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value,
		METADATA_SPRITESHEET_FIRST_FRAME: get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value,
		METADATA_SPRITESHEET_LAST_FRAME: get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value,
		METADATA_SPEED: get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").value,
		METADATA_IS_MIRROR: get_node(MIRROR_NODE).button_pressed
	}

	var metadata_array_offset: int = get_metadata_array_offset()

	anim_metadata[metadata_array_offset] = metadata_dict

	if direction_selected == DIR_UP or direction_selected == DIR_DOWN:
		return

	# If this direction has already been mirrored, replicate the changes
	var opp_dir = find_opposite_direction(direction_selected)
	var opp_metadata_array_offset: int = get_metadata_array_offset(opp_dir)
	if anim_metadata[opp_metadata_array_offset][METADATA_IS_MIRROR]:
		mirror_animation(direction_selected, opp_dir)


# Updates the metadata to mirror animation "source" to animation "dest"
# The "source" animation is the animation that really exists as sprite frames
# in the animated sprite
func mirror_animation(source: String, dest: String) -> void:
	var texture
	var rect_location
	var frame_being_copied = Image.new()
	var frame_counter: int = 0
#
	var metadata_source_offset = get_metadata_array_offset(source)
	var current_anim_type = return_current_animation_type()
	var dest_anim_name = "%s_%s" % [current_anim_type, dest]

	var metadata_dict = {
		METADATA_ANIM_NAME: dest_anim_name,
		METADATA_SPRITESHEET_SOURCE_FILE: anim_metadata[metadata_source_offset][METADATA_SPRITESHEET_SOURCE_FILE],
		METADATA_SPRITESHEET_FRAMES_HORIZ: anim_metadata[metadata_source_offset][METADATA_SPRITESHEET_FRAMES_HORIZ],
		METADATA_SPRITESHEET_FRAMES_VERT: anim_metadata[metadata_source_offset][METADATA_SPRITESHEET_FRAMES_VERT],
		METADATA_SPRITESHEET_FIRST_FRAME: anim_metadata[metadata_source_offset][METADATA_SPRITESHEET_FIRST_FRAME],
		METADATA_SPRITESHEET_LAST_FRAME: anim_metadata[metadata_source_offset][METADATA_SPRITESHEET_LAST_FRAME],
		METADATA_SPEED: anim_metadata[metadata_source_offset][METADATA_SPEED],
		METADATA_IS_MIRROR: true
	}

	var metadata_dest_offset = get_metadata_array_offset(dest)
	anim_metadata[metadata_dest_offset] = metadata_dict
	disconnect_selector_signals()
	reset_arrow_colours()
	connect_selector_signals()

func unmirror_animation(anim_to_unmirror: String) -> void:
	var metadata_dict = {
		METADATA_ANIM_NAME: "tbc",
		METADATA_SPRITESHEET_SOURCE_FILE: "tbc",
		METADATA_SPRITESHEET_FRAMES_HORIZ: -1,
		METADATA_SPRITESHEET_FRAMES_VERT: -1,
		METADATA_SPRITESHEET_FIRST_FRAME: 0,
		METADATA_SPRITESHEET_LAST_FRAME: 0,
		METADATA_SPEED: 30,
		METADATA_IS_MIRROR: false
	}
	spritesheet_settings[2] = 0
	spritesheet_settings[3] = 0
	var metadata_dest_offset = get_metadata_array_offset(anim_to_unmirror)
	anim_metadata[metadata_dest_offset] = metadata_dict
	reset_arrow_colours()


# Shows the preview animation. Required as the no_anim_found sprite doesn't always cover the
# whole preview due to UI peculiarities.
func preview_show():
	get_node(PREVIEW_NODE).get_node("no_anim_found_sprite").visible = false
	get_node(PREVIEW_NODE).get_node("anim_preview_sprite").visible = true


# Hides the preview animation. Required when the no_anim_found sprite doesn't cover the
# whole preview due to UI peculiarities.
func preview_hide():
	get_node(PREVIEW_NODE).get_node("no_anim_found_sprite").visible = true
	get_node(PREVIEW_NODE).get_node("anim_preview_sprite").visible = false


# Creates the "in_progress" animation which is shown in the UI as the animation preview based
# on the currently selected settings.
#
# A mirrored animation (frames in reverse order and sprites horizontally flipped) is generated here
# for the purpose of the preview but isn't generated in the final export as it relies on ESCPlayer's
# is_mirrored setting.
func preview_update() -> void:
	if get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value > 0:
		check_frame_limits()

		var current_anim_type = return_current_animation_type()
		var anim_name = "%s_%s" % [current_anim_type, direction_selected]
		var offset = get_metadata_array_offset()
		var generate_mirror = get_node(MIRROR_NODE).button_pressed

		var texture
		var rect_location
		var frame_counter: int = 0
		var frame_duration: float = 1.0
		var frame_being_copied: Image = Image.create_empty(frame_size.x, frame_size.y, false, source_image.get_format())

		get_node(PREVIEW_NODE).get_node("anim_preview_sprite").sprite_frames.clear(ANIM_IN_PROGRESS)

		for loop in range(get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value - get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value + 1):
			rect_location = calc_frame_coords(get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value + loop)
			frame_being_copied.blit_rect(source_image, Rect2(rect_location, Vector2(frame_size.x, frame_size.y)), Vector2(0, 0))

			if generate_mirror:
				frame_being_copied.flip_x()

			texture = ImageTexture.create_from_image(frame_being_copied)
			# Remove the image filter to make pixel correct graphics
			#texture.set_flags(2) # Godot 4 no longer allows for the setting of "repetition" (and other) flags
			
			get_node(PREVIEW_NODE).get_node("anim_preview_sprite").sprite_frames.add_frame(ANIM_IN_PROGRESS, texture, frame_duration, frame_counter)
			frame_counter += 1

		preview_show()

		# Calculate the scale to make the preview as big as possible in the preview window depending on
		# the height to width ratio of the frame
		var preview_scale = Vector2.ONE
		preview_scale.x = get_node(PREVIEW_BGRND_NODE).size.x / frame_size.x
		preview_scale.y = get_node(PREVIEW_BGRND_NODE).size.y / frame_size.y

		if preview_scale.y > preview_scale.x:
			get_node(PREVIEW_NODE).get_node("anim_preview_sprite").scale = Vector2(preview_scale.x, preview_scale.x)
		else:
			get_node(PREVIEW_NODE).get_node("anim_preview_sprite").scale = Vector2(preview_scale.y, preview_scale.y)
	else:
		preview_hide()


# Ensure that the spritesheet settings are valid
func check_frame_limits():
	var max_frame = get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value * get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value

	if get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value > max_frame:
		get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = max_frame

	if get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value > max_frame:
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = max_frame

	if get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value > get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value:
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value

# If any spritesheet settings have changed, display the "store animation" button to save the changes.
# If the values are manually reset after a change to the previously stored settings, the button will disappear.
func check_if_controls_have_changed():
	var metadata_array_offset: int = get_metadata_array_offset()
	var metadata_entry = anim_metadata[metadata_array_offset]

	if autostore == true:
		return

	# Need to check this or it registers if you load a sprite and set the number of horizontal
	# or vertical frames and haven't set a start/end frame yet
	if get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value > 0:
		get_node(STORE_ANIM_NODE).visible = \
			get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").value != metadata_entry[METADATA_SPEED] \
			or get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value != metadata_entry[METADATA_SPRITESHEET_FIRST_FRAME] \
			or get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value != metadata_entry[METADATA_SPRITESHEET_LAST_FRAME] \
			or get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value != metadata_entry[METADATA_SPRITESHEET_FRAMES_HORIZ] \
			or get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value != metadata_entry[METADATA_SPRITESHEET_FRAMES_VERT]


# If the user tries to change settings before they've loaded a spritesheet, this will display
# a warning window instead of letting them change settings.
func has_spritesheet_been_loaded() -> bool:
	if source_image == null:
		get_node(GENERIC_ERROR_NODE).dialog_text = "Please load a spritesheet to begin."
		get_node(GENERIC_ERROR_NODE).popup_centered()
		return false
	return true


func animation_on_dir_up_pressed() -> void:
	check_activate_direction(DIR_UP)


# Runs when the direction arrow is clicked
func animation_on_dir_right_pressed() -> void:
	check_activate_direction(DIR_RIGHT)


# Runs when the direction arrow is clicked
func animation_on_dir_left_pressed() -> void:
	check_activate_direction(DIR_LEFT)


# Runs when the direction arrow is clicked
func animation_on_dir_down_pressed() -> void:
	check_activate_direction(DIR_DOWN)


# Runs when the direction arrow is clicked
func animation_on_dir_downright_pressed() -> void:
	check_activate_direction(DIR_DOWN_RIGHT)


# Runs when the direction arrow is clicked
func animation_on_dir_downleft_pressed() -> void:
	check_activate_direction(DIR_DOWN_LEFT)


# Runs when the direction arrow is clicked
func animation_on_dir_upright_pressed() -> void:
	check_activate_direction(DIR_UP_RIGHT)


# Runs when the direction arrow is clicked
func animation_on_dir_upleft_pressed() -> void:
	check_activate_direction(DIR_UP_LEFT)


# If the user tries to mirror an animation, ensure they're not trying to mirror an already
# mirrored direction, and that the direction they're trying to mirror has been created.
func animation_on_mirror_checkbox_toggled(button_pressed: bool) -> void:
	if not has_spritesheet_been_loaded():
		get_node(GENERIC_ERROR_NODE).dialog_text = "No animation has been configured."
		get_node(GENERIC_ERROR_NODE).popup_centered()
		get_node(MIRROR_NODE).button_pressed = false
		return

	var opp_dir = find_opposite_direction(direction_selected)
	var opp_anim_name="%s_%s" % [return_current_animation_type(), opp_dir]
	var metadata_array_offset: int = get_metadata_array_offset(opp_dir)

	if button_pressed:
		if anim_metadata[metadata_array_offset][METADATA_IS_MIRROR]:
			get_node(GENERIC_ERROR_NODE).dialog_text = \
				"You can't mirror a direction that is already mirrored."
			get_node(GENERIC_ERROR_NODE).popup_centered()
			get_node(MIRROR_NODE).set_pressed_no_signal(false)
			return

		if anim_metadata[metadata_array_offset][METADATA_SPRITESHEET_FIRST_FRAME] == 0:
			get_node(GENERIC_ERROR_NODE).dialog_text = \
				"You can't mirror an animation that hasn't been set up."
			get_node(GENERIC_ERROR_NODE).popup_centered()
			get_node(MIRROR_NODE).set_pressed_no_signal(false)
			return

		mirror_animation(opp_dir, direction_selected)
		preview_update()
	else:
		unmirror_animation(direction_selected)


# When the animation speed has been changed, update the speed and label
func controls_on_anim_speed_scroll_bar_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").value = current_animation_speed
		return

	if anim_metadata[get_metadata_array_offset()][METADATA_IS_MIRROR] and not currently_changing_direction:
		get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").value = current_animation_speed
		get_node(GENERIC_ERROR_NODE).dialog_text = "You cannot change a mirrored animation."
		get_node(GENERIC_ERROR_NODE).popup_centered()
		return

	current_animation_speed = int(value)

	check_if_controls_have_changed()

	get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_label").text = "%s: %s FPS" % [ANIMATION_SPEED_LABEL, value]
	get_node(PREVIEW_NODE).get_node("anim_preview_sprite").sprite_frames.set_animation_speed(ANIM_IN_PROGRESS, value)

	preview_update()

	if autostore == true:
		store_on_anim_store_button_pressed()


# When the first animation frame setting is changed, update the animation preview appropriately
func controls_on_start_frame_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = spritesheet_settings[2]
		return

	if anim_metadata[get_metadata_array_offset()][METADATA_IS_MIRROR] and not currently_changing_direction:
		get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = spritesheet_settings[2]
		get_node(GENERIC_ERROR_NODE).dialog_text = "You cannot change a mirrored animation."
		get_node(GENERIC_ERROR_NODE).popup_centered()
		return
	spritesheet_settings[2] = get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value
	if get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value > 0:
		preview_show()
		check_if_controls_have_changed()
	draw_frame_outlines()
	preview_update()

	if autostore == true:
		store_on_anim_store_button_pressed()


# When the last animation frame setting is changed, update the animation preview appropriately
func controls_on_end_frame_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = spritesheet_settings[3]
		return

	if anim_metadata[get_metadata_array_offset()][METADATA_IS_MIRROR] and not currently_changing_direction:
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = spritesheet_settings[3]
		get_node(GENERIC_ERROR_NODE).dialog_text = "You cannot change a mirrored animation."
		get_node(GENERIC_ERROR_NODE).popup_centered()
		return

	spritesheet_settings[3] = get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value
	if get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value > 0:
		if get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value == 0:
			get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = 1
			spritesheet_settings[2] = 1
		preview_show()
		check_if_controls_have_changed()

	draw_frame_outlines()
	preview_update()

	if autostore == true:
		store_on_anim_store_button_pressed()


# When the number of horizontal frames in the spritesheet setting is changed,
# update the animation preview appropriately
func controls_on_h_frames_spin_box_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = spritesheet_settings[0]
		return

	if anim_metadata[get_metadata_array_offset()][METADATA_IS_MIRROR] and not currently_changing_direction:
		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = spritesheet_settings[0]
		get_node(GENERIC_ERROR_NODE).dialog_text = "You cannot change a mirrored animation."
		get_node(GENERIC_ERROR_NODE).popup_centered()
		return

	spritesheet_settings[0] = get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value
	preview_show()

	check_if_controls_have_changed()
	calc_sprite_size()
	draw_frame_outlines()
	preview_update()

	if autostore == true:
		store_on_anim_store_button_pressed()


# When the number of vertical frames in the spritesheet setting is changed,
# update the animation preview appropriately
func controls_on_v_frames_spin_box_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = spritesheet_settings[1]
		return

	if anim_metadata[get_metadata_array_offset()][METADATA_IS_MIRROR] and not currently_changing_direction:
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = spritesheet_settings[1]
		get_node(GENERIC_ERROR_NODE).dialog_text = "You cannot change a mirrored animation."
		get_node(GENERIC_ERROR_NODE).popup_centered()
		return

	spritesheet_settings[1] = get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value

	preview_show()

	check_if_controls_have_changed()
	calc_sprite_size()
	draw_frame_outlines()
	preview_update()

	if autostore == true:
		store_on_anim_store_button_pressed()


# Load a spritesheet when selected in the file browser
func controls_on_FileDialog_file_selected(path: String) -> void:
	get_node(NO_SPRITESHEET_NODE).visible = false
	load_spritesheet(path)


# Check all animations have been created when the user wants to export the ESCPlayer
func spritesheet_on_export_button_pressed() -> void:
	var missing_walk_animations: int = 0
	var missing_talk_animations: int = 0
	var missing_idle_animations: int = 0
	var anim_name: String = ""
	var dirnames = []

	var scene_name = "%s/%s.scn" % [get_node(CHARACTER_PATH_NODE).text, get_node(NAME_NODE).get_node("node_name").text]

	if FileAccess.file_exists(scene_name):
		get_node(GENERIC_ERROR_NODE).dialog_text = \
			"Scene file '%s' already exists.\nPlease change Global_ID or path,\nor delete scene before continuing.\n" \
			% scene_name
		get_node(GENERIC_ERROR_NODE).popup_centered()
		return

	if get_node(DIR_COUNT_NODE).get_node("four_directions").button_pressed:
		dirnames = DIR_LIST_4
	elif get_node(DIR_COUNT_NODE).get_node("eight_directions").button_pressed:
		dirnames = DIR_LIST_8
	elif get_node(DIR_COUNT_NODE).get_node("two_directions").button_pressed:
		dirnames = DIR_LIST_2
	else:
		dirnames = DIR_LIST_1

	for dirloop in dirnames:
		anim_name = "%s_%s" % [TYPE_WALK, dirloop]

		if anim_metadata[get_metadata_array_offset(dirloop, TYPE_WALK)][METADATA_SPRITESHEET_FIRST_FRAME] == 0:
				missing_walk_animations += 1

		anim_name = "%s_%s" % [TYPE_TALK, dirloop]

		if anim_metadata[get_metadata_array_offset(dirloop, TYPE_TALK)][METADATA_SPRITESHEET_FIRST_FRAME] == 0:
				missing_talk_animations += 1

		anim_name = "%s_%s" % [TYPE_IDLE, dirloop]

		if anim_metadata[get_metadata_array_offset(dirloop, TYPE_IDLE)][METADATA_SPRITESHEET_FIRST_FRAME] == 0:
				missing_idle_animations += 1

	if missing_idle_animations + missing_talk_animations + missing_walk_animations > 0:
		get_node(GENERIC_ERROR_NODE).dialog_text = \
			"One or more animations are not configured.\nPlease ensure all arrows are green for\nwalk, talk, and idle animations.\n\n"

		if missing_walk_animations:
			get_node(GENERIC_ERROR_NODE).dialog_text += \
				"%s walk animations not configured.\n" % missing_walk_animations

		if missing_talk_animations:
			get_node(GENERIC_ERROR_NODE).dialog_text += \
				"%s talk animations not configured.\n" % missing_talk_animations

		if missing_idle_animations:
			get_node(GENERIC_ERROR_NODE).dialog_text += \
				"%s idle animations not configured." % missing_idle_animations

		get_node(GENERIC_ERROR_NODE).popup_centered()

		return

#	export_thread = Thread.new()
#	export_thread.start(self, "export_player")
	export_player(scene_name)

# Update the spritesheet zoom and scrollbars
func spritesheet_on_zoom_scrollbar_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		return

	zoom_value = snapped(value, 0.1)
	get_node(ZOOM_LABEL_NODE).text = "Zoom: %sx" % str(zoom_value)
	if zoom_value > 1.0:
		get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").custom_minimum_size = source_image.get_size() * zoom_value
		get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").scale = Vector2.ONE
	else:
		get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").custom_minimum_size = source_image.get_size()
		get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").scale.x = zoom_value
		get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").scale.y = zoom_value
	draw_frame_outlines()


# Show the file manager when the load spritesheet button is pressed
func spritesheet_on_load_spritesheet_button_pressed() -> void:
	get_node(FILE_DIALOG_NODE).popup_centered()


# Reset zoom settings when the reset button is pushed. Also called when a new
# spritesheet is loaded.
func spritesheet_on_zoom_reset_button_pressed() -> void:
	if not has_spritesheet_been_loaded():
		return

	get_node(ZOOM_SCROLL_NODE).value = 1

	get_node(SCROLL_VBOX_NODE).get_node("spritesheet_scroll_container").scroll_horizontal = 0
	get_node(SCROLL_VBOX_NODE).get_node("spritesheet_scroll_container").scroll_vertical = 0


# If the node name is changed, update the global_id to match.
# NOTE : Updating the global_id doesn't update the nodename, allowing them to be different.
func nodename_on_node_name_text_changed(new_text: String) -> void:
	get_node(NAME_NODE).get_node("global_id").text = new_text


# If 8 directions was already selected, don't let it be unselected.
# If 4 directions was selected, unselect it.
func directions_on_eight_directions_pressed() -> void:
	if not get_node(DIR_COUNT_NODE).get_node("eight_directions").button_pressed:
		# Don't let them untick all boxes
		get_node(DIR_COUNT_NODE).get_node("eight_directions").button_pressed = true

	for loop in ["four_directions", "two_directions", "one_direction"]:
		get_node(DIR_COUNT_NODE).get_node(loop).button_pressed = false
	reset_arrow_colours()


# If 4 directions was already selected, don't let it be unselected.
# If previously selected direction is now invalid, change it to a valid one.
func directions_on_four_directions_pressed() -> void:
	if not get_node(DIR_COUNT_NODE).get_node("four_directions").button_pressed:
		# Don't let them untick all boxes
		get_node(DIR_COUNT_NODE).get_node("four_directions").button_pressed = true
	else:
		# Current direction is illegal
		for loop in ["eight_directions", "two_directions", "one_direction"]:
			get_node(DIR_COUNT_NODE).get_node(loop).button_pressed = false
		if not direction_selected in DIR_LIST_4:
			direction_selected = DIR_UP
			activate_direction(DIR_UP)
	reset_arrow_colours()


# If 2 directions was already selected, don't let it be unselected.
# If previously selected direction is now invalid, change it to a valid one.
func directions_on_two_directions_pressed() -> void:
	if not get_node(DIR_COUNT_NODE).get_node("two_directions").button_pressed:
		# Don't let them untick all boxes
		get_node(DIR_COUNT_NODE).get_node("two_directions").button_pressed = true
	else:
		for loop in ["eight_directions", "four_directions", "one_direction"]:
			get_node(DIR_COUNT_NODE).get_node(loop).button_pressed = false
		# Current direction is illegal
		if not direction_selected in DIR_LIST_2:
			direction_selected = DIR_RIGHT
			activate_direction(DIR_RIGHT)
	reset_arrow_colours()


# If 1 direction was already selected, don't let it be unselected.
# If previously selected direction is now invalid, change it to a valid one.
func directions_on_one_direction_pressed() -> void:
	if not get_node(DIR_COUNT_NODE).get_node("one_direction").button_pressed:
		# Don't let them untick all boxes
		get_node(DIR_COUNT_NODE).get_node("one_direction").button_pressed = true
	else:
		for loop in ["eight_directions", "four_directions", "two_directions"]:
			get_node(DIR_COUNT_NODE).get_node(loop).button_pressed = false
		# Current direction is illegal
		if not direction_selected in DIR_LIST_1:
			direction_selected = DIR_DOWN
			activate_direction(DIR_DOWN)
	reset_arrow_colours()

# Returns the currently selected animation type
func return_current_animation_type() -> String:
	var animation_type: String = ""

	if get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed:
		animation_type = TYPE_WALK
	elif get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed:
		animation_type = TYPE_TALK
	elif get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed:
		animation_type = TYPE_IDLE

	assert(not animation_type.is_empty(), "No animation type selected.")

	return animation_type


# Runs whenever a direction arrow is clicked. If the store button is visible (i.e. the settings
# for the sprite frames have changed since they were last stored) the selected direction isn't
# changed and a confirmation window is shown instead.
func check_activate_direction(direction) -> void:
	direction_requested = direction

	if get_node(STORE_ANIM_NODE).visible:
		get_node(ARROWS_NODE).get_node("Container_%s" % direction).get_node("set_dir_%s" % direction).button_pressed = false
		get_node(ARROWS_NODE).get_node("Container_%s" % direction).get_node("unset_dir_%s" % direction).button_pressed = false
		$InformationWindows/unstored_changes_window.popup_centered()
	else:
		activate_direction(direction)


# Change the selected direction. This clears the selected direction arrow and mirror settings.
# If the selected direction has an animation, it will be displayed, if not, the "no animation"
# graphic will be displayed in the preview window.
# Spritesheet control values are set based on the direction chosen (if it had a previous animation)
# If it used a different spritesheet, that will be loaded.
func activate_direction(direction) -> void:
	var anim_type = return_current_animation_type()
	var arrows = get_tree().get_nodes_in_group("direction_buttons")
	var anim_name = "%s_%s" % [anim_type, direction]

	currently_changing_direction = true
	direction_selected = direction

	for arrow in arrows:
		arrow.button_pressed = false

	if direction == DIR_UP or direction == DIR_DOWN:
		get_node(MIRROR_NODE).visible = false
	else:
		get_node(MIRROR_NODE).visible = true

	get_node(MIRROR_NODE).set_pressed_no_signal(false)

	# If no animation has been created yet for this direction
	if anim_metadata[get_metadata_array_offset()][METADATA_SPRITESHEET_FIRST_FRAME] == 0:
		get_node(ARROWS_NODE).get_node("Container_%s" % direction).get_node("unset_dir_%s" % direction).button_pressed = true
		spritesheet_settings[2] = 0
		spritesheet_settings[3] = 0

		get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = 0
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = 0
		preview_hide()
	else:
		get_node(ARROWS_NODE).get_node("Container_%s" % direction).get_node("set_dir_%s" % direction).button_pressed = true

		var metadata = anim_metadata[get_metadata_array_offset()]

		assert(metadata[METADATA_ANIM_NAME] == anim_name, \
			"Anim %s expected in metadata array. Found %s" % [anim_name, metadata[METADATA_ANIM_NAME]])

		if metadata[METADATA_SPRITESHEET_SOURCE_FILE] != get_node(CURRENT_SHEET_NODE).text:
			load_spritesheet(metadata[METADATA_SPRITESHEET_SOURCE_FILE])

		# Disconnect the signals so if we're changing to a mirrored direction it doesn't complain
		# when all the settings update
#		disconnect_selector_signals()
		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = metadata[METADATA_SPRITESHEET_FRAMES_HORIZ]
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = metadata[METADATA_SPRITESHEET_FRAMES_VERT]
		get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = metadata[METADATA_SPRITESHEET_FIRST_FRAME]
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = metadata[METADATA_SPRITESHEET_LAST_FRAME]
		get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").value = metadata[METADATA_SPEED]
		get_node(MIRROR_NODE).set_pressed_no_signal(metadata[METADATA_IS_MIRROR])
#		connect_selector_signals()
		preview_update()

		# Restart animation otherwise it will first complete all the frames before changing to the new animation
		get_node(PREVIEW_NODE).get_node("anim_preview_sprite").stop()
		get_node(PREVIEW_NODE).get_node("anim_preview_sprite").play()
	currently_changing_direction = false

# Store the metadata for the animation changes for the current direction
func store_on_anim_store_button_pressed() -> void:
	get_node(STORE_ANIM_NODE).visible = false

	var anim_type = return_current_animation_type()
	store_animation("%s_%s" % [anim_type, direction_selected])

	reset_arrow_colours()


# Based on the type of animation and direction, find its array position in the metadata array.
func get_metadata_array_offset(dir_to_retrieve = "default", anim_type = "default") -> int:
	var offset: int = 0

	if anim_type == "default":
		anim_type = return_current_animation_type()

	if anim_type == TYPE_TALK:
		offset = 8
	elif anim_type == TYPE_IDLE:
		offset = 16

	if dir_to_retrieve == "default":
		dir_to_retrieve = direction_selected

	var dir_offset: int = DIR_LIST_8.find(dir_to_retrieve)

	assert(dir_offset > -1, "Could not find direction in list. This should never happen.")

	return offset + dir_offset


# Using both set and unset buttons (instead of changing the texture to a different colour) as
# updating the direction arrow sprite was causing issues due to Godot storing the
# sprite by reference rather than by value. It was easier to duplicate the sprites/buttons.
func reset_arrow_colours() -> void:
	var arrows = get_tree().get_nodes_in_group("direction_buttons")
	for arrow in arrows:
		arrow.visible = false

	get_node(ARROWS_NODE).get_node("Container_up").get_node("ColorRectSpacer").visible = false
	get_node(ARROWS_NODE).get_node("Container_left").get_node("ColorRectSpacer").visible = false
	get_node(ARROWS_NODE).get_node("Container_down").get_node("ColorRectSpacer").visible = false
	var dir_list=DIR_LIST_8
	if get_node(DIR_COUNT_NODE).get_node("four_directions").button_pressed:
		dir_list=DIR_LIST_4
		if not direction_selected in DIR_LIST_4:
			direction_selected = DIR_UP
#		get_node(ARROWS_NODE).get_node("Container_up").get_node("ColorRectSpacer").visible = true
	if get_node(DIR_COUNT_NODE).get_node("two_directions").button_pressed:
		dir_list=DIR_LIST_2
		if not direction_selected in DIR_LIST_2:
			direction_selected = DIR_RIGHT
		get_node(ARROWS_NODE).get_node("Container_up").get_node("ColorRectSpacer").visible = true
		get_node(ARROWS_NODE).get_node("Container_down").get_node("ColorRectSpacer").visible = true
	if get_node(DIR_COUNT_NODE).get_node("one_direction").button_pressed:
		dir_list=DIR_LIST_1
		if not direction_selected in DIR_LIST_1:
			direction_selected = DIR_DOWN
		get_node(ARROWS_NODE).get_node("Container_up").get_node("ColorRectSpacer").visible = true
		get_node(ARROWS_NODE).get_node("Container_left").get_node("ColorRectSpacer").visible = true


	for dir in dir_list:
		if anim_metadata[get_metadata_array_offset(dir)][METADATA_SPRITESHEET_FIRST_FRAME] > 0:
			get_node(ARROWS_NODE).get_node("Container_%s" % dir).get_node("set_dir_%s" % dir).visible = true
			get_node(ARROWS_NODE).get_node("Container_%s" % dir).get_node("unset_dir_%s" % dir).visible = false
		else:
			get_node(ARROWS_NODE).get_node("Container_%s" % dir).get_node("set_dir_%s" % dir).visible = false
			get_node(ARROWS_NODE).get_node("Container_%s" % dir).get_node("unset_dir_%s" % dir).visible = true

	# This works when you change between animation types
	# eg. walk and talk - to ensure that the arrow will get changed back from selected with stored
	# animation to selected with unstored animation if needs be. It also resets the preview.
	activate_direction(direction_selected)


# If the user tries to change direction without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to save the changes, then will update
# the interface to select the new direction.
func unstored_warning_on_commit_button_pressed() -> void:
	get_node(UNSTORED_CHANGE_NODE).visible = false
	get_node(STORE_ANIM_NODE).visible = false

	var anim_type = return_current_animation_type()
	store_animation("%s_%s" % [anim_type, direction_selected])

	reset_arrow_colours()

	activate_direction(direction_requested)


# If the user tries to change direction without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to lose the changes, then will update
# the interface to select the new direction.
func unstored_warning_on_lose_button_pressed() -> void:
	get_node(UNSTORED_CHANGE_NODE).visible = false
	get_node(STORE_ANIM_NODE).visible = false

	activate_direction(direction_requested)


# If the user tries to change direction without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to cancel the request to change direction
# and let the user continue to edit the current animation.
func unstored_warning_on_cancel_button_pressed() -> void:
	get_node(UNSTORED_CHANGE_NODE).visible = false


# Returns the opposite direction for mirroring animations
func find_opposite_direction(direction:String) -> String:
	var opposite_dir: String = ""

	match direction:
		DIR_UP_RIGHT:
			opposite_dir = DIR_UP_LEFT
		DIR_RIGHT:
			opposite_dir = DIR_LEFT
		DIR_DOWN_RIGHT:
			opposite_dir = DIR_DOWN_LEFT
		DIR_DOWN_LEFT:
			opposite_dir = DIR_DOWN_RIGHT
		DIR_LEFT:
			opposite_dir = DIR_RIGHT
		DIR_UP_LEFT:
			opposite_dir = DIR_UP_RIGHT

	assert(not opposite_dir.is_empty(), "This should never happen : direction = %s" % direction)
	return opposite_dir


# Creates an ESCPlayer node based on the settings configured in the wizard.
# It will save it as a scene (named based on the name provided in the GUI text box)
# and open it in the Godot editor - which is why this utility has to run as a plugin.
# This will also create an ESCDialogue position, and a collision box. The collision box will
# be sized based on the widest and tallest frames encountered during export (note that the
# widest/tallest frame settings do not necessarily come from the same animation frame but are
# from all the animation frames.
func export_player(scene_name) -> void:
	var num_directions
	var start_angle_array
	var angle_size
	var dirnames

	var plugin_reference = get_node("..").plugin_reference

	disconnect_selector_signals()
	get_node(EXPORT_PROGRESS_NODE).popup_centered()
	get_node(EXPORT_PROGRESS_NODE).get_node("progress_bar").value = 0
	get_node(EXPORT_PROGRESS_NODE).get_node("progress_bar").visible = true
	get_node(EXPORT_PROGRESS_NODE).get_node("progress_label").visible = true

	if get_node(DIR_COUNT_NODE).get_node("eight_directions").button_pressed:
		num_directions = 8
	if get_node(DIR_COUNT_NODE).get_node("four_directions").button_pressed:
		num_directions = 4
	if get_node(DIR_COUNT_NODE).get_node("two_directions").button_pressed:
		num_directions = 2
	else:
		num_directions = 1

	var new_character
	# NPCs can't be ESCPlayers or the player won't walk up to them when
	# you interact with them
	if get_node(CHAR_TYPE_NODE).get_node("npc").button_pressed:
		new_character = ESCItem.new()
	else:
		new_character = ESCPlayer.new()
		new_character.selectable = true
	new_character.name = get_node(NAME_NODE).get_node("node_name").text

	if get_node(NAME_NODE).get_node("global_id").text.is_empty():
		new_character.global_id = new_character.name
	else:
		new_character.global_id = get_node(NAME_NODE).get_node("global_id").text

	new_character.tooltip_name = new_character.name

	new_character.default_action = "look"

	var animations_resource = ESCAnimationResource.new()

	# This is necessary to avoid a Godot bug when appending to one array
	# appends to all arrays in the same class (possibly for resources only).
	animations_resource.dir_angles = []
	animations_resource.directions = []
	animations_resource.idles = []
	animations_resource.speaks = []

	if get_node(DIR_COUNT_NODE).get_node("four_directions").button_pressed:
		num_directions = 4
		start_angle_array = [315, 45, 135, 225]
		angle_size = 90
		dirnames = DIR_LIST_4
	elif get_node(DIR_COUNT_NODE).get_node("eight_directions").button_pressed:
		num_directions = 8
		start_angle_array = [337, 22, 67, 112, 157, 202, 247, 292]
		angle_size = 45
		dirnames = DIR_LIST_8
	elif get_node(DIR_COUNT_NODE).get_node("two_directions").button_pressed:
		num_directions = 2
		start_angle_array = [0, 180]
		angle_size = 180
		dirnames = DIR_LIST_2
	else:
		num_directions = 1
		start_angle_array = [0]
		angle_size = 360
		dirnames = DIR_LIST_1

	for loop in range(num_directions):
		# Need to create new objects here each time in order to avoid having multiple references
		# to the same objects.
		var dir_angle = ESCDirectionAngle.new()
		var anim_details: ESCAnimationName

		dir_angle.angle_start = start_angle_array[loop]
		dir_angle.angle_size = angle_size
		animations_resource.dir_angles.append(dir_angle)

		anim_details = _create_esc_animation(TYPE_WALK, dirnames[loop])
		animations_resource.directions.append(anim_details)

		anim_details = _create_esc_animation(TYPE_TALK, dirnames[loop])
		animations_resource.speaks.append(anim_details)

		anim_details = _create_esc_animation(TYPE_IDLE, dirnames[loop])
		animations_resource.idles.append(anim_details)

#	var largest_sprite = export_generate_animations(new_character, num_directions)
	export_largest_sprite = Vector2.ONE

	# TODO: This call updates export_largest_sprite, and there is likely a better
	# way to accomplish this.
	await export_generate_animations(new_character, num_directions)

	# Add Collision shape to the ESCPlayer
	var rectangle_shape = RectangleShape2D.new()
	var collision_shape = CollisionShape2D.new()
	progress_bar_update("Creating collision shape")
	await get_tree().process_frame

	collision_shape.shape = rectangle_shape
	collision_shape.shape.size = export_largest_sprite
	collision_shape.position.y = -(export_largest_sprite.y / 2)

	new_character.add_child(collision_shape)
	progress_bar_update("Setting up dialog position")
	await get_tree().process_frame

	# Add Dialog Position to the ESCPlayer
	var dialog_position = ESCDialogLocation.new()
	dialog_position.name = "ESCDialogLocation"
	dialog_position.position.y = -(export_largest_sprite.y * 1.2)
	new_character.add_child(dialog_position)

	if get_node(CHAR_TYPE_NODE).get_node("npc").button_pressed:
	# Add Interaction Position to an NPC
		var interaction_position = ESCLocation.new()
		interaction_position.name = "interact_position"
		interaction_position.position.y = +(export_largest_sprite.y * 1.2)
		new_character.add_child(interaction_position)
		interaction_position.set_owner(new_character)

	progress_bar_update("Configuring animations")
	await get_tree().process_frame
	# Make it so all the nodes can be seen in the scene tree
	new_character.animations = animations_resource
	progress_bar_update("Adding child to scene tree")
	await get_tree().process_frame
	get_tree().edited_scene_root.add_child(new_character)
	new_character.set_owner(get_tree().edited_scene_root)

	# Making the owner "new_character" rather than "get_tree().edited_scene_root" means that
	# when saving as a packed scene, the child nodes get saved under the parent (as the parent
	# must own the child nodes). If the owner is not the scene root though, the nodes will NOT
	# show up in the scene tree.
	collision_shape.set_owner(new_character)
	dialog_position.set_owner(new_character)

	# Export scene
	var packed_scene = PackedScene.new()

	progress_bar_update("Packing scene - this might take up to 30 seconds")
	await get_tree().process_frame
	packed_scene.pack(get_tree().edited_scene_root.get_node(NodePath(new_character.name)))

	progress_bar_update("Resource saving - this might take up to 30 seconds")
	await get_tree().process_frame
	# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript

	# Make sure the path exists
	if not DirAccess.dir_exists_absolute(scene_name.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(scene_name.get_base_dir())

	ResourceSaver.save(packed_scene, scene_name, ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS|ResourceSaver.FLAG_COMPRESS)

	progress_bar_update("Releasing resources - this might take up to 30 seconds")
	await get_tree().process_frame
	new_character.queue_free()

	get_tree().edited_scene_root.get_node(NodePath(new_character.name)).queue_free()
	plugin_reference.open_scene(scene_name)
	plugin_reference._make_visible(false)
	get_node(EXPORT_PROGRESS_NODE).hide()
	get_node(EXPORT_COMPLETE_NODE).popup_centered()

	connect_selector_signals()


# Updates the text in the export window so the user knows what's happening
func progress_bar_update(message, bar_increase_amount = 1) -> void:
	get_node(PROGRESS_LABEL_NODE).text = message
	get_node(EXPORT_PROGRESS_NODE).get_node("progress_bar").value += bar_increase_amount


# When exporting the ESCPlayer, this function loads the relevant spritesheets based on the
# animation metadata, and copies the frames to the relevant animations within the animatedsprite
# attached to the ESCPlayer.
#func export_generate_animations(character_node, num_directions) -> Vector2:
func export_generate_animations(character_node, num_directions) -> void:
	# This variable is used instead of running this function in a thread as I hit this issue
	# when I tried to thread this - https://github.com/godotengine/godot/issues/38058
	var display_refresh_timer:int = Time.get_ticks_msec()
	var direction_names
	var loaded_spritesheet: String
	var largest_frame_dimensions: Vector2 = Vector2.ZERO
	var sprite_frames = SpriteFrames.new()
	var default_anim_length = 0
	var default_anim_speed = 1
	var frame_counter: int = 0

	match num_directions:
		1: direction_names = DIR_LIST_1
		2: direction_names = DIR_LIST_2
		4: direction_names = DIR_LIST_4
		8: direction_names = DIR_LIST_8

	for animtype in [TYPE_WALK, TYPE_TALK, TYPE_IDLE]:
		for anim_dir in direction_names:
			# Using this in place of threads due to the above mentioned issue so that the
			# UI continues to update while the export is running
			var current_ticks = Time.get_ticks_msec()
			if current_ticks - display_refresh_timer > 30:
				await get_tree().process_frame

				display_refresh_timer = current_ticks

			if num_directions == 4:
				progress_bar_update("Processing "+str(animtype)+" "+str(anim_dir),2)
			else:
				progress_bar_update("Processing "+str(animtype)+" "+str(anim_dir),1)

			var anim_name = "%s_%s" % [animtype, anim_dir]
			var metadata = anim_metadata[get_metadata_array_offset(anim_dir, animtype)]

			if metadata[METADATA_IS_MIRROR]:
				continue

			var rect_location
			sprite_frames.add_animation(anim_name)

			if metadata[METADATA_SPRITESHEET_SOURCE_FILE] != loaded_spritesheet:
				load_spritesheet(metadata[METADATA_SPRITESHEET_SOURCE_FILE], true, get_metadata_array_offset(anim_dir, animtype))

				loaded_spritesheet = metadata[METADATA_SPRITESHEET_SOURCE_FILE]
				calc_sprite_size()
				if (frame_size.x / 2) > largest_frame_dimensions.x:
					largest_frame_dimensions.x = frame_size.x

				if (frame_size.y / 2) > largest_frame_dimensions.y:
					largest_frame_dimensions.y = frame_size.y

			if animtype == TYPE_IDLE and anim_dir == "down":
				default_anim_length = metadata[METADATA_SPRITESHEET_LAST_FRAME] - metadata[METADATA_SPRITESHEET_FIRST_FRAME]  + 1
				default_anim_speed = metadata[METADATA_SPEED]

			var frame_duration: float = 1.0
			var frame_being_copied: Image = Image.create_empty(frame_size.x, frame_size.y, false, source_image.get_format())

			for loop in range(metadata[METADATA_SPRITESHEET_LAST_FRAME] - metadata[METADATA_SPRITESHEET_FIRST_FRAME]  + 1):
				rect_location = calc_frame_coords(metadata[METADATA_SPRITESHEET_FIRST_FRAME] + loop)
				frame_being_copied.blit_rect(source_image, Rect2(rect_location, Vector2(frame_size.x, frame_size.y)), Vector2(0, 0))
				var texture: ImageTexture = ImageTexture.create_from_image(frame_being_copied)

				# Remove "filter" flag so it's pixel perfect
				#texture.set_flags(2)
				sprite_frames.add_frame(anim_name, texture, frame_duration, frame_counter)
				sprite_frames.set_animation_speed(anim_name, metadata[METADATA_SPEED])
				frame_counter += 1

	# Generate default animation. This is used by the object manager to set the
	# state when the object is registered. If there's no current state, the
	# default animation will be used.
	var frame_duration: float = 1.0

	for loop in range(default_anim_length):
		var texture: ImageTexture = sprite_frames.get_frame_texture("idle_down", loop)

		# Remove "filter" flag so it's pixel perfect
		#texture.set_flags(2)
		sprite_frames.add_frame("default", texture, frame_duration, loop)
		sprite_frames.set_animation_speed("default", default_anim_speed)

	var animated_sprite = AnimatedSprite2D.new()

	progress_bar_update("Adding sprite frames to node")
	animated_sprite.sprite_frames = sprite_frames
	if num_directions == 2:
		animated_sprite.animation = "%s_%s" % [TYPE_IDLE, DIR_RIGHT]
	else:
		animated_sprite.animation = "%s_%s" % [TYPE_IDLE, DIR_DOWN]
	animated_sprite.position.y = -(largest_frame_dimensions.y / 2)	# Place feet at (0,0)
	animated_sprite.animation = "default"
	animated_sprite.play()

	character_node.add_child(animated_sprite)
	# Making the owner "character_node" rather than "get_tree().edited_scene_root" means that
	# when saving as a packed scene, the child nodes get saved under the parent (as the parent
	# must own the child nodes). If the owner is not the scene root though, the nodes will NOT
	# show up in the scene tree.
	animated_sprite.set_owner(character_node)
	#return largest_frame_dimensions
	export_largest_sprite = largest_frame_dimensions


# Open the help window
func spritesheet_on_help_button_pressed() -> void:
	$InformationWindows/help_window.popup_centered()
	$InformationWindows/help_window.show_page()


func spritesheet_on_reset_button_pressed() -> void:
	$InformationWindows/ConfirmationDialog.dialog_text = "WARNING!\n\n" + \
		"If you continue you will lose the current character."
	$InformationWindows/ConfirmationDialog.popup_centered()


func spritesheet_on_reset_confirmed() -> void:
	spritesheet_settings = [1, 1, 0, 0]
	source_image = null
	get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").texture = null
	create_empty_animations()
	character_creator_reset()


func spritesheet_on_MainMenuConfirmation_confirmed() -> void:
	get_node("../Menu").visible = true
	get_node(".").visible = false


func spritesheet_on_main_menu_button_up() -> void:
	$InformationWindows/MainMenuConfirmation.popup_centered()


func load_settings() -> void:
	var file_path = "res://"

	if FileAccess.file_exists(CONFIG_FILE):
		var file: FileAccess = FileAccess.open(CONFIG_FILE, FileAccess.READ)
		file_path = file.get_pascal_string()
		file.close()

	get_node(CHARACTER_PATH_NODE).text = file_path


# Creates and returns an ESCAnimationName for use by ESCAnimationResource
#
# #### Parameters
#
# - type: One of TYPE_WALK, TYPE_TALK, TYPE_IDLE (these are consts defined at the top of this script)
# - dir_name: One of DIR_LIST_8's or DIR_LIST_4's entries (these are consts defined at the top of this script)
#
# *Returns* a valid ESCAnimationName object.
func _create_esc_animation(type: String, dir_name: String) -> ESCAnimationName:
	var anim_details = ESCAnimationName.new()

	anim_details.animation = "%s_%s" % [type, dir_name]

	if anim_metadata[get_metadata_array_offset(dir_name, type)][METADATA_IS_MIRROR]:
		anim_details.mirrored = true
		anim_details.animation = "%s_%s" % [type, find_opposite_direction(dir_name)]
	else:
		anim_details.mirrored = false
	return anim_details


func _on_character_path_change_button_pressed() -> void:
	get_node(CHARACTER_FILE_NODE).popup_centered()


func _on_CharacterPathFileDialog_dir_selected(dir: String) -> void:
	get_node(CHARACTER_PATH_NODE).text = dir
	var file: FileAccess = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	file.store_pascal_string(dir)
	file.close()


# Mouse clicks inside the spritesheet
func _on_control_gui_input(event: InputEvent) -> void:
	var clicked_tile: Vector2

	if event.is_pressed():
		var num_horiz_frames = get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value
		var num_vert_frames = get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value

		clicked_tile.x = int(event.position.x / (frame_size.x * zoom_value))
		if clicked_tile.x >= num_horiz_frames:
			return
		clicked_tile.y = int(event.position.y / (frame_size.y * zoom_value))
		if clicked_tile.y >= num_vert_frames:
			return

		var absolute_frame = ((clicked_tile.y * num_horiz_frames) + clicked_tile.x) + 1

		if event.button_index == MOUSE_BUTTON_LEFT:
			get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = absolute_frame
		if event.button_index == MOUSE_BUTTON_RIGHT:
			get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = absolute_frame


# If the user tries to change animation type without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to save the changes, then will update
# the interface to select the new direction.
func unstored_animchange_warning_on_commit_button_pressed() -> void:
	get_node(UNSTORED_ANIMTYPE_CHANGE_NODE).visible = false
	get_node(STORE_ANIM_NODE).visible = false
	var anim_type = return_current_animation_type()
	store_animation("%s_%s" % [anim_type, direction_selected])
	change_animation_type(animation_type_requested)
	reset_arrow_colours()

# If the user tries to change animation type without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to lose the changes, then will update
# the interface to select the new direction.
func unstored_animchange_warning_on_lose_button_pressed() -> void:
	get_node(UNSTORED_ANIMTYPE_CHANGE_NODE).visible = false
	get_node(STORE_ANIM_NODE).visible = false
	change_animation_type(animation_type_requested)
	reset_arrow_colours()


# If the user tries to change animation type without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to cancel the request to change direction
# and let the user continue to edit the current animation.
func unstored_animchange_warning_on_cancel_button_pressed() -> void:
	get_node(UNSTORED_ANIMTYPE_CHANGE_NODE).visible = false


func change_animation_type(anim_type) -> void:
	if anim_type == "walk":
		get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed = true
		get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed = false
		get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed = false
		animation_type_selected = "walk"
	elif anim_type == "talk":
		get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed = true
		get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed = false
		get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed = false
		animation_type_selected = "talk"
	else:	# idle
		get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed = true
		get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed = false
		get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed = false
		animation_type_selected = "idle"
	reset_arrow_colours()


# If the walk button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean that none of walk/talk/idle were selected.
func animation_on_walk_checkbox_pressed() -> void:
	# Don't let the checkbox be unselected if it's currently selected
	if animation_type_selected == "walk":
		get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed = true
		return
	if get_node(STORE_ANIM_NODE).visible:
		# Reset the buttons back to how they were
		get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed = false
		if animation_type_selected == "talk":
			get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed = true
		if animation_type_selected == "idle":
			get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed = true
		animation_type_requested="walk"
		get_node(UNSTORED_ANIMTYPE_CHANGE_NODE).popup_centered()
	else:
		change_animation_type("walk")


# If the talk button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean  that none of walk/talk/idle were selected.
func animation_on_talk_checkbox_pressed() -> void:
	# Don't let the checkbox be unselected if it's currently selected
	if animation_type_selected == "talk":
		get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed = true
		return
	if get_node(STORE_ANIM_NODE).visible:
		# Reset the buttons back to how they were
		get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed = false
		if animation_type_selected == "idle":
			get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed = true
		if animation_type_selected == "walk":
			get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed = true
		animation_type_requested="talk"
		get_node(UNSTORED_ANIMTYPE_CHANGE_NODE).popup_centered()
	else:
		change_animation_type("talk")


# If the idle button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean  that none of walk/talk/idle were selected.
func animation_on_idle_checkbox_pressed() -> void:
	# Don't let the checkbox be unselected if it's currently selected
	if animation_type_selected == "idle":
		get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed = true
		return
	if get_node(STORE_ANIM_NODE).visible:
		# Reset the buttons back to how they were
		get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").button_pressed = false
		if animation_type_selected == "talk":
			get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").button_pressed = true
		if animation_type_selected == "walk":
			get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").button_pressed = true
		animation_type_requested="idle"
		get_node(UNSTORED_ANIMTYPE_CHANGE_NODE).popup_centered()
	else:
		change_animation_type("idle")


# When Auto storage checkbox is checked
func _on_AutoStoreCheckBox_toggled(button_pressed: bool) -> void:
	autostore = button_pressed


# When player checkbox selected
func _on_player_pressed():
# If player button was already selected, don't let it be unselected.
	get_node(CHAR_TYPE_NODE).get_node("player").button_pressed = true
	get_node(CHAR_TYPE_NODE).get_node("npc").button_pressed = false


# When NPC checkbox selected
func _on_npc_pressed():
# If npc button was already selected, don't let it be unselected.
	get_node(CHAR_TYPE_NODE).get_node("npc").button_pressed = true
	get_node(CHAR_TYPE_NODE).get_node("player").button_pressed = false
