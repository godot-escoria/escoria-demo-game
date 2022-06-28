# Outstanding proposed features
# v1.0
# * A help page
# * GUI refactor to use Godot UI fluff
# * It would also be good to pop up a window at the end to tell the user what they need to do now
# ** i.e. adjust the position of the dialog_position node, change the collisionshape if they don't like it
# ** set the node as the player node of their ESCRoom
# ** move the created ESCPlayer node to wherever they're keeping their player nodes.
# * An "@ here" on Discord to tell everyone about it
#
# v1.1 features
# * Your suggestion of having the editor kick in when an ESCPlayer is selected, i.e. "load/edit"
# * Add a settings page (if there's enough features to warrant it). This would have the path the scene gets written to,  default angles for each direction so the developer can change them from the default 90s / 45s they are now, whether the ESCPlayer is click-through, errr can't think of anything else.
# * Redo the Escoria tutorial to use the plugin.

tool
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

const TYPE_WALK = "walk"
const TYPE_TALK = "talk"
const TYPE_IDLE = "idle"

const ANIM_IN_PROGRESS = "in_progress"

# Make the code more readable by shortening node references using constants
const NAME_NODE          = "MarginContainer/HBoxContainer/configuration/VBoxContainer/node_name/MarginContainer2/GridContainer"
const DIR_COUNT_NODE     = "MarginContainer/HBoxContainer/configuration/VBoxContainer/directions/HBoxContainer"
const ANIM_TYPE_NODE     = "MarginContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer"
const MIRROR_NODE        = "MarginContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer2/HBoxContainer/MarginContainer3/mirror_checkbox"
const ARROWS_NODE        = "MarginContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer2/HBoxContainer/MarginContainer2/GridContainer"
const PREVIEW_NODE       = "MarginContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer2/preview/MarginContainer"
const PREVIEW_BGRND_NODE = "MarginContainer/HBoxContainer/configuration/VBoxContainer/animation/HBoxContainer2/preview/anim_preview_background"
const ANIM_CONTROLS_NODE = "MarginContainer/HBoxContainer/spritesheet_controls/VBoxContainer/GridContainer"
const STORE_ANIM_NODE    = "MarginContainer/HBoxContainer/spritesheet_controls/VBoxContainer/Control/store_anim"
const SCROLL_CTRL_NODE   = "MarginContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/spritesheet_scroll_container/control"
const SCROLL_VBOX_NODE   = "MarginContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/"
const CURRENT_SHEET_NODE = "MarginContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/zoom_current/MarginContainer2/current_spritesheet_label"
const ZOOM_LABEL_NODE    = "MarginContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/zoom_scroll/zoom_label"
const ZOOM_SCROLL_NODE   = "MarginContainer/HBoxContainer/spritesheet/MarginContainer/VBoxContainer/zoom_scroll/MarginContainer/zoom_scrollbar"

# Test flag - set to true to load test data.
var test_mode: bool = false

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
# This is the array that stores the data for each animation.
var anim_metadata = []
# This variable is set by plugin.gd and used to allow the plugin to interact with the Godot
# editor (open the ESCPlayer scene in the editor once it's created)
var plugin_reference


func _ready() -> void:
	get_node(NAME_NODE).get_node("node_name").text = "replace_me"
	get_node(DIR_COUNT_NODE).get_node("four_directions").pressed = true
	get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").pressed = true
	get_node(SCROLL_VBOX_NODE).get_node("spritesheet_scroll_container/control/MarginContainer/no_spritesheet_found_sprite").visible = true
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
	get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = 1
	get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = 1
	""
	get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = 1
	get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = 1
	get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").value = 5
	get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_label").text="Animation Speed : 5 FPS"
	get_node(CURRENT_SHEET_NODE).text="No spritesheet loaded."

	# Connect all the signals now the base settings are configured to stop program logic firing during setup
	get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").connect("value_changed", self, "controls_on_h_frames_spin_box_value_changed")
	get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").connect("value_changed", self, "controls_on_v_frames_spin_box_value_changed")
	get_node(ANIM_CONTROLS_NODE).get_node("start_frame").connect("value_changed", self, "controls_on_start_frame_value_changed")
	get_node(ANIM_CONTROLS_NODE).get_node("end_frame").connect("value_changed", self, "controls_on_end_frame_value_changed")
	get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").connect("value_changed", self, "controls_on_anim_speed_scroll_bar_value_changed")

	if test_mode:
		setup_test_data()


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
	load_spritesheet("res://addons/escoria-player-creator/graphics/mark-animtest.png")

	var start_frames = [15, 10, 7, 10, 12, 14, 1, 14, 12, 3, 1, 1]
	var end_frames = [17, 14, 9, 14, 13, 18, 3, 18, 12, 3, 1, 22]
	var mirrored = [0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0,]
	var sourcefile = [0, 0, 0, 0, 2, 2, 1, 2, 2, 0, 0, 0]
	var fps = [3, 3, 1, 3, 3, 3, 1, 3, 3, 3, 1, 3]

	for loop in range(12):
		if sourcefile[loop] == 0:
			anim_metadata[loop * 2][METADATA_SPRITESHEET_SOURCE_FILE] = "res://addons/escoria-player-creator/graphics/mark-animtest.png"
			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_HORIZ] = 8
			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_VERT] = 3
		elif sourcefile[loop] == 1:
			anim_metadata[loop * 2][METADATA_SPRITESHEET_SOURCE_FILE] = "res://game/characters/mark/png/mark_talk_down.png"
			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_HORIZ] = 3
			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_VERT] = 1
		else:
			anim_metadata[loop * 2][METADATA_SPRITESHEET_SOURCE_FILE] = "res://game/characters/mark/png/markjester_talk.png"
			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_HORIZ] = 21
			anim_metadata[loop * 2][METADATA_SPRITESHEET_FRAMES_VERT] = 1

		anim_metadata[loop * 2][METADATA_SPRITESHEET_FIRST_FRAME] = start_frames[loop]
		anim_metadata[loop * 2][METADATA_SPRITESHEET_LAST_FRAME] = end_frames[loop]
		anim_metadata[loop * 2][METADATA_SPEED] = fps[loop]

		anim_metadata[loop * 2][METADATA_IS_MIRROR] = mirrored[loop] != 0

	get_node(SCROLL_VBOX_NODE).get_node("spritesheet_scroll_container/control/MarginContainer/no_spritesheet_found_sprite").visible = false

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
		METADATA_SPRITESHEET_FIRST_FRAME: -1,
		METADATA_SPRITESHEET_LAST_FRAME: -1,
		METADATA_SPEED: 30,
		METADATA_IS_MIRROR: false
	}

	var local_dict

	for typeloop in [TYPE_WALK, TYPE_TALK, TYPE_IDLE]:
		for dirloop in DIR_LIST_8:
			local_dict = metadata_dict.duplicate()
			local_dict[METADATA_ANIM_NAME] = "%s_%s" % [typeloop, dirloop]
			anim_metadata.append(local_dict)

	sframes.add_animation(ANIM_IN_PROGRESS)

	get_node(PREVIEW_NODE).get_node("anim_preview_sprite").frames = sframes


# Loads a spritesheet and calculates the size of each sprite frame if loading a spritesheet
# to show a previously stored animation.
func load_spritesheet(file_to_load, read_settings_from_metadata: bool = false, metadata_frame: int = 0) -> void:
	if source_image == null:
		source_image = Image.new()

	var errorval = source_image.load(file_to_load)

	assert(not errorval, "Error loading file %s" % str(file_to_load))

	var texture = ImageTexture.new()
	texture.create_from_image(source_image)
	texture.set_flags(2)

	get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").texture = texture

	frame_size = source_image.get_size()

	if read_settings_from_metadata:
		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = anim_metadata[metadata_frame][METADATA_SPRITESHEET_FRAMES_HORIZ]
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = anim_metadata[metadata_frame][METADATA_SPRITESHEET_FRAMES_VERT]
	else:
		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = 1
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = 1

	calc_sprite_size()

	get_node(CURRENT_SHEET_NODE).text = file_to_load
	draw_frame_outlines()
	spritesheet_on_zoom_reset_button_pressed()

	# Make scroll bars appear if necessary

	get_node(SCROLL_CTRL_NODE).rect_min_size = source_image.get_size() * zoom_value


# Draws an outline on the spritesheet to show which frames are included in the current animation
func draw_frame_outlines() -> void:
	check_frame_limits()
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").zoom_factor = zoom_value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").total_num_columns = get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").start_cell = get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").end_cell = get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").cell_size = frame_size
	get_node(SCROLL_CTRL_NODE).get_node("frame_rectangles").update()


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
		METADATA_IS_MIRROR: get_node(MIRROR_NODE).pressed
	}

	var metadata_array_offset: int = get_metadata_array_offset()

	anim_metadata[metadata_array_offset] = metadata_dict


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
	check_frame_limits()

	var current_anim_type = return_current_animation_type()
	var anim_name = "%s_%s" % [current_anim_type, direction_selected]
	var offset = get_metadata_array_offset()
	var generate_mirror = get_node(MIRROR_NODE).pressed

	var texture
	var rect_location
	var frame_being_copied = Image.new()
	var frame_counter: int = 0

	get_node(PREVIEW_NODE).get_node("anim_preview_sprite").frames.clear(ANIM_IN_PROGRESS)

	frame_being_copied.create(frame_size.x, frame_size.y, false, source_image.get_format())

	for loop in range(get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value - get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value + 1):
		texture = ImageTexture.new()

		if generate_mirror:
			rect_location = calc_frame_coords(get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value - loop)
		else:
			rect_location = calc_frame_coords(get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value + loop)

		frame_being_copied.blit_rect(source_image, Rect2(rect_location, Vector2(frame_size.x, frame_size.y)), Vector2(0, 0))

		if generate_mirror:
			frame_being_copied.flip_x()

		texture.create_from_image(frame_being_copied)

		# Remove the image filter to make pixel correct graphics
		texture.set_flags(2)

		get_node(PREVIEW_NODE).get_node("anim_preview_sprite").frames.add_frame(ANIM_IN_PROGRESS, texture, frame_counter)

		frame_counter += 1

	preview_show()

	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	var preview_scale = Vector2.ONE
	preview_scale.x = get_node(PREVIEW_BGRND_NODE).rect_size.x / frame_size.x
	preview_scale.y = get_node(PREVIEW_BGRND_NODE).rect_size.y / frame_size.y

	if preview_scale.y > preview_scale.x:
		get_node(PREVIEW_NODE).get_node("anim_preview_sprite").scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		get_node(PREVIEW_NODE).get_node("anim_preview_sprite").scale = Vector2(preview_scale.y, preview_scale.y)


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
		$information_windows/generic_error_window.dialog_text = "Please load a spritesheet to begin."
		$information_windows/generic_error_window.popup()
		return false

	return true


# If the walk button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean that none of walk/talk/idle were selected.
func animation_on_walk_checkbox_pressed() -> void:
	if not get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").pressed:
		get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").pressed = true
	get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").pressed = false
	get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").pressed = false

	reset_arrow_colours()


# If the talk button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean  that none of walk/talk/idle were selected.
func animation_on_talk_checkbox_pressed() -> void:
	if not get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").pressed:
		get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").pressed = true
	get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").pressed = false
	get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").pressed = false

	reset_arrow_colours()


# If the idle button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean  that none of walk/talk/idle were selected.
func animation_on_idle_checkbox_pressed() -> void:
	if not get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").pressed:
		get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").pressed = true
	get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").pressed = false
	get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").pressed = false

	reset_arrow_colours()


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
	var opp_dir = find_opposite_direction(direction_selected)
	var opp_anim_name="%s_%s" % [return_current_animation_type(), opp_dir]
	var metadata_array_offset: int = get_metadata_array_offset(opp_dir)

	if button_pressed:
		if anim_metadata[metadata_array_offset][METADATA_IS_MIRROR]:
			$information_windows/generic_error_window.dialog_text = \
				"You cant mirror a direction that is already mirrored."
			$information_windows/generic_error_window.popup()
			get_node(MIRROR_NODE).pressed = false
			return

		if anim_metadata[metadata_array_offset][METADATA_SPRITESHEET_FIRST_FRAME] == -1:
			$information_windows/generic_error_window.dialog_text = \
				"You cant mirror an animation that hasn't been set up."
			$information_windows/generic_error_window.popup()
			get_node(MIRROR_NODE).pressed = false
			return

		mirror_animation(opp_dir, direction_selected)
	else:
		anim_metadata[get_metadata_array_offset(direction_selected)][METADATA_IS_MIRROR] = false
	preview_update()

# When the animation speed has been changed, update the speed and label
func controls_on_anim_speed_scroll_bar_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		return

	current_animation_speed = int(value)

	check_if_controls_have_changed()

	get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_label").text = "Animation Speed : %s FPS" % value
	get_node(PREVIEW_NODE).get_node("anim_preview_sprite").frames.set_animation_speed(ANIM_IN_PROGRESS, value)

	preview_update()


# When the first animation frame setting is changed, update the animation preview appropriately
func controls_on_start_frame_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		return

	preview_show()

	check_if_controls_have_changed()
	draw_frame_outlines()
	preview_update()


# When the last animation frame setting is changed, update the animation preview appropriately
func controls_on_end_frame_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		return

	preview_show()

	check_if_controls_have_changed()
	draw_frame_outlines()
	preview_update()


# When the number of horizontal frames in the spritesheet setting is changed,
# update the animation preview appropriately
func controls_on_h_frames_spin_box_value_changed(value: float) -> void:
	if ! has_spritesheet_been_loaded():
		return

	preview_show()

	check_if_controls_have_changed()
	calc_sprite_size()
	draw_frame_outlines()
	preview_update()


# When the number of vertical frames in the spritesheet setting is changed,
# update the animation preview appropriately
func controls_on_v_frames_spin_box_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		return

	preview_show()

	check_if_controls_have_changed()
	calc_sprite_size()
	draw_frame_outlines()
	preview_update()


# Load a spritesheet when selected in the file browser
func controls_on_FileDialog_file_selected(path: String) -> void:
	get_node(SCROLL_VBOX_NODE).get_node("spritesheet_scroll_container/control/MarginContainer/no_spritesheet_found_sprite").visible = false
	load_spritesheet(path)


# Check all animations have been created when the user wants to export the ESCPlayer
func spritesheet_on_export_button_pressed() -> void:
	var missing_walk_animations: int = 0
	var missing_talk_animations: int = 0
	var missing_idle_animations: int = 0
	var anim_name: String = ""
	var dirnames = []

	if get_node(DIR_COUNT_NODE).get_node("four_directions").pressed:
		dirnames = DIR_LIST_4
	else:
		dirnames = DIR_LIST_8

	for dirloop in dirnames:
		anim_name = "%s_%s" % [TYPE_WALK, dirloop]

		if anim_metadata[get_metadata_array_offset(dirloop, TYPE_WALK)][METADATA_SPRITESHEET_FIRST_FRAME] == -1:
				missing_walk_animations += 1

		anim_name = "%s_%s" % [TYPE_TALK, dirloop]

		if anim_metadata[get_metadata_array_offset(dirloop, TYPE_TALK)][METADATA_SPRITESHEET_FIRST_FRAME] == -1:
				missing_talk_animations += 1

		anim_name = "%s_%s" % [TYPE_IDLE, dirloop]

		if anim_metadata[get_metadata_array_offset(dirloop, TYPE_IDLE)][METADATA_SPRITESHEET_FIRST_FRAME] == -1:
				missing_idle_animations += 1

	if missing_idle_animations + missing_talk_animations + missing_walk_animations > 0:
		$information_windows/generic_error_window.dialog_text = \
			"One or more animations are not configured.\nPlease ensure all arrows are green for\nwalk, talk, and idle animations.\n\n"

		if missing_walk_animations:
			$information_windows/generic_error_window.dialog_text += \
				"%s walk animations not configured.\n" % missing_walk_animations

		if missing_talk_animations:
			$information_windows/generic_error_window.dialog_text += \
				"%s talk animations not configured.\n" % missing_talk_animations

		if missing_idle_animations:
			$information_windows/generic_error_window.dialog_text += \
				"%s idle animations not configured." % missing_idle_animations

		$information_windows/generic_error_window.popup()

		return
	export_player()


# Update the spritesheet zoom and scrollbars
func spritesheet_on_zoom_scrollbar_value_changed(value: float) -> void:
	if not has_spritesheet_been_loaded():
		return
	zoom_value = stepify(value, 0.1)


	get_node(ZOOM_LABEL_NODE).text = "Zoom: %sx" % str(zoom_value)
	get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").scale.x = zoom_value
	get_node(SCROLL_CTRL_NODE).get_node("spritesheet_sprite").scale.y = zoom_value
	get_node(SCROLL_CTRL_NODE).rect_min_size = source_image.get_size() * zoom_value
	draw_frame_outlines()


# Show the file manager when the load spritesheet button is pressed
func spritesheet_on_load_spritesheet_button_pressed() -> void:
	$FileDialog.popup()


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
	if not get_node(DIR_COUNT_NODE).get_node("eight_directions").pressed:
		# Don't let them untick all boxes
		get_node(DIR_COUNT_NODE).get_node("eight_directions").pressed = true

	get_node(DIR_COUNT_NODE).get_node("four_directions").pressed = false

	reset_arrow_colours()


# If 4 directions was already selected, don't let it be unselected.
# If 8 directions was selected, unselect it. Also if the previously selected direction was
# a diagonal, reset the selection to up as the diagonal is no longer valid.
func directions_on_four_directions_pressed() -> void:
	if not get_node(DIR_COUNT_NODE).get_node("four_directions").pressed:
		# Don't let them untick all boxes
		get_node(DIR_COUNT_NODE).get_node("four_directions").pressed = true
	else:
		# Current direction is diagonal
		if not direction_selected in DIR_LIST_4:
			direction_selected = DIR_UP
			activate_direction(DIR_UP)

	get_node(DIR_COUNT_NODE).get_node("eight_directions").pressed = false
	reset_arrow_colours()


# Returns the currently selected animation type
func return_current_animation_type() -> String:
	var animation_type: String = ""

	if get_node(ANIM_TYPE_NODE).get_node("walk_checkbox").pressed:
		animation_type = TYPE_WALK
	elif get_node(ANIM_TYPE_NODE).get_node("talk_checkbox").pressed:
		animation_type = TYPE_TALK
	elif get_node(ANIM_TYPE_NODE).get_node("idle_checkbox").pressed:
		animation_type = TYPE_IDLE

	assert(not animation_type.empty(), "No animation type selected.")

	return animation_type


# Runs whenever a direction arrow is clicked. If the store button is visible (i.e. the settings
# for the sprite frames have changed since they were last stored) the selected direction isn't
# changed and a confirmation window is shown instead.
func check_activate_direction(direction) -> void:
	direction_requested = direction

	if get_node(STORE_ANIM_NODE).visible:
		var button_name = "set_dir_%s" % direction

		get_node(ARROWS_NODE).get_node("Container_%s" % direction).get_node("set_dir_%s" % direction).pressed = false
		get_node(ARROWS_NODE).get_node("Container_%s" % direction).get_node("unset_dir_%s" % direction).pressed = false
		$information_windows/unstored_changes_window.popup()
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

	direction_selected = direction

	for arrow in arrows:
		arrow.pressed = false

	if direction == DIR_UP or direction == DIR_DOWN:
		get_node(MIRROR_NODE).visible = false
	else:
		get_node(MIRROR_NODE).visible = true
		get_node(MIRROR_NODE).set_pressed_no_signal(false)

	if anim_metadata[get_metadata_array_offset()][METADATA_SPRITESHEET_FIRST_FRAME] == -1:
		get_node(ARROWS_NODE).get_node("Container_%s" % direction).get_node("unset_dir_%s" % direction).pressed = true
		preview_hide()
	else:
		get_node(ARROWS_NODE).get_node("Container_%s" % direction).get_node("set_dir_%s" % direction).pressed = true

		var metadata = anim_metadata[get_metadata_array_offset()]

		assert(metadata[METADATA_ANIM_NAME] == anim_name, \
			"Anim %s expected in metadata array. Found %s" % [anim_name, metadata[METADATA_ANIM_NAME]])

		if metadata[METADATA_SPRITESHEET_SOURCE_FILE] != get_node(CURRENT_SHEET_NODE).text:
			load_spritesheet(metadata[METADATA_SPRITESHEET_SOURCE_FILE])

		get_node(ANIM_CONTROLS_NODE).get_node("h_frames_spin_box").value = metadata[METADATA_SPRITESHEET_FRAMES_HORIZ]
		get_node(ANIM_CONTROLS_NODE).get_node("v_frames_spin_box").value = metadata[METADATA_SPRITESHEET_FRAMES_VERT]
		get_node(ANIM_CONTROLS_NODE).get_node("start_frame").value = metadata[METADATA_SPRITESHEET_FIRST_FRAME]
		get_node(ANIM_CONTROLS_NODE).get_node("end_frame").value = metadata[METADATA_SPRITESHEET_LAST_FRAME]
		get_node(ANIM_CONTROLS_NODE).get_node("anim_speed_scroll_bar").value = metadata[METADATA_SPEED]
		get_node(MIRROR_NODE).set_pressed_no_signal(metadata[METADATA_IS_MIRROR])

		preview_update()

		# Restart animation otherwise it will first complete all the frames before changing to the new animation
		get_node(PREVIEW_NODE).get_node("anim_preview_sprite").playing = false
		get_node(PREVIEW_NODE).get_node("anim_preview_sprite").playing = true


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
	var current_animation_type = return_current_animation_type()
	var current_animation_name

	for dir in DIR_LIST_8:
		current_animation_name = "%s_%s" % [current_animation_type, dir]

		if anim_metadata[get_metadata_array_offset(dir)][METADATA_SPRITESHEET_FIRST_FRAME] > -1:
			get_node(ARROWS_NODE).get_node("Container_%s" % dir).get_node("set_dir_%s" % dir).visible = true
			get_node(ARROWS_NODE).get_node("Container_%s" % dir).get_node("unset_dir_%s" % dir).visible = false
		else:
			get_node(ARROWS_NODE).get_node("Container_%s" % dir).get_node("set_dir_%s" % dir).visible = false
			get_node(ARROWS_NODE).get_node("Container_%s" % dir).get_node("unset_dir_%s" % dir).visible = true

	if get_node(DIR_COUNT_NODE).get_node("four_directions").pressed:
		var arrows = get_tree().get_nodes_in_group("8_direction_buttons")

		for arrow in arrows:
			arrow.visible = false

	# Current direction is diagonal
	if not direction_selected in DIR_LIST_4:
		direction_selected = DIR_UP
		activate_direction(DIR_UP)

	# This works when you change between animation types
	# eg. walk and talk - to ensure that the arrow will get changed back from selected with stored
	# animation to selected with unstored animation if needs be. It also resets the preview.
	activate_direction(direction_selected)


# If the user tries to change direction without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to save the changes, then will update
# the interface to select the new direction.
func unstored_warning_on_commit_button_pressed() -> void:
	$information_windows/unstored_changes_window.visible = false
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
	$information_windows/unstored_changes_window.visible = false
	get_node(STORE_ANIM_NODE).visible = false

	activate_direction(direction_requested)


# If the user tries to change direction without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to cancel the request to change direction
# and let the user continue to edit the current animation.
func unstored_warning_on_cancel_button_pressed() -> void:
	$information_windows/unstored_changes_window.visible = false


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

	assert(not opposite_dir.empty(), "This should never happen : direction = %s" % direction)

	return opposite_dir


# Creates an ESCPlayer node based on the settings configured in the wizard.
# It will save it as a scene (named based on the name provided in the GUI text box)
# and open it in the Godot editor - which is why this utility has to run as a plugin.
# This will also create an ESCDialogue position, and a collision box. The collision box will
# be sized based on the widest and tallest frames encountered during export (note that the
# widest/tallest frame settings do not necessarily come from the same animation frame but are
# from all the animation frames.
func export_player() -> void:
	var num_directions
	var start_angle_array
	var angle_size
	var dirnames

	$information_windows/export_progress.popup()
	$information_windows/export_progress/progress_bar.value = 0

	if get_node(DIR_COUNT_NODE).get_node("eight_directions").pressed:
		num_directions = 8
	else:
		num_directions = 4

	var new_character = ESCPlayer.new()
	new_character.name = get_node(NAME_NODE).get_node("node_name").text

	if get_node(NAME_NODE).get_node("global_id").text == null:
		new_character.global_id = new_character.name

	new_character.global_id = get_node(NAME_NODE).get_node("global_id").text

	var animations_resource = ESCAnimationResource.new()

	# This is necessary to avoid a Godot bug when appending to one array
	# appends to all arrays in the same class (possibly for resources only).
	animations_resource.dir_angles = []
	animations_resource.directions = []
	animations_resource.idles = []
	animations_resource.speaks = []

	if get_node(DIR_COUNT_NODE).get_node("four_directions").pressed:
		num_directions = 4
		start_angle_array = [315, 45, 135, 225]
		angle_size = 90
		dirnames = DIR_LIST_4
	else:
		num_directions = 8
		start_angle_array = [338, 22, 69, 114, 159, 204, 249, 294]
		angle_size = 45
		dirnames = DIR_LIST_8

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

	# Add Dialog Position to the ESCPlayer
	var dialog_position = Position2D.new()
	dialog_position.name = "dialog_position"
	new_character.add_child(dialog_position)

	var largest_sprite = export_generate_animations(new_character, num_directions)

	# Add Collision shape to the ESCPlayer
	var rectangle_shape = RectangleShape2D.new()
	var collision_shape = CollisionShape2D.new()

	collision_shape.shape = rectangle_shape
	collision_shape.shape.extents = largest_sprite

	new_character.add_child(collision_shape)

	# Make it so all the nodes can be seen in the scene tree
	new_character.animations = animations_resource
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

	packed_scene.pack(get_tree().edited_scene_root.get_node(new_character.name))
	ResourceSaver.save("res://%s.tscn" % get_node(NAME_NODE).get_node("node_name").text, packed_scene)

	# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript
	ResourceSaver.save("res://%s.tscn" % get_node(NAME_NODE).get_node("node_name").text, packed_scene, ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

	new_character.queue_free()
	get_tree().edited_scene_root.get_node(new_character.name).queue_free()
	plugin_reference.open_scene("res://%s.tscn" % get_node(NAME_NODE).get_node("node_name").text)
	$information_windows/export_progress.hide()
	$information_windows/export_complete.popup()

# When exporting the ESCPlayer, this function loads the relevant spritesheets based on the
# animation metadata, and copies the frames to the relevant animations within the animatedsprite
# attached to the ESCPlayer.
func export_generate_animations(character_node, num_directions) -> Vector2:
	var direction_names
	var loaded_spritesheet: String
	var largest_frame_dimensions: Vector2 = Vector2.ZERO
	var sprite_frames = SpriteFrames.new()

	if num_directions == 4:
		direction_names = DIR_LIST_4
	else:
		direction_names = DIR_LIST_8

	for animtype in [TYPE_WALK, TYPE_TALK, TYPE_IDLE]:
		for anim_dir in direction_names:
			var anim_name = "%s_%s" % [animtype, anim_dir]
			var metadata = anim_metadata[get_metadata_array_offset(anim_dir, animtype)]

			if metadata[METADATA_IS_MIRROR]:
				continue

			var texture
			var rect_location
			var frame_being_copied = Image.new()
			var frame_counter: int = 0

			sprite_frames.add_animation(anim_name)

			if metadata[METADATA_SPRITESHEET_SOURCE_FILE] != loaded_spritesheet:
				load_spritesheet(metadata[METADATA_SPRITESHEET_SOURCE_FILE], true, get_metadata_array_offset(anim_dir, animtype))

				loaded_spritesheet = metadata[METADATA_SPRITESHEET_SOURCE_FILE]

				if (frame_size.x / 2) > largest_frame_dimensions.x:
					largest_frame_dimensions.x = frame_size.x / 2

				if (frame_size.y / 2) > largest_frame_dimensions.y:
					largest_frame_dimensions.y = frame_size.y / 2

			frame_being_copied.create(frame_size.x, frame_size.y, false, source_image.get_format())

			for loop in range(metadata[METADATA_SPRITESHEET_LAST_FRAME] - metadata[METADATA_SPRITESHEET_FIRST_FRAME]  + 1):
				texture = ImageTexture.new()

				rect_location = calc_frame_coords(metadata[METADATA_SPRITESHEET_FIRST_FRAME] + loop)

				frame_being_copied.blit_rect(source_image, Rect2(rect_location, Vector2(frame_size.x, frame_size.y)), Vector2(0, 0))

				texture.create_from_image(frame_being_copied)

				# Remove "filter" flag so it's pixel perfect
				texture.set_flags(2)

				sprite_frames.add_frame (anim_name, texture, frame_counter )
				sprite_frames.set_animation_speed(anim_name, metadata[METADATA_SPEED])

				frame_counter += 1
			if num_directions == 4:
				$information_windows/export_progress/progress_bar.value += 2
			else:
				$information_windows/export_progress/progress_bar.value += 1
	sprite_frames.remove_animation("default")

	var animated_sprite = AnimatedSprite.new()

	animated_sprite.frames = sprite_frames
	animated_sprite.animation = "%s_%s" % [TYPE_IDLE, DIR_DOWN]
	character_node.add_child(animated_sprite)

	# Making the owner "character_node" rather than "get_tree().edited_scene_root" means that
	# when saving as a packed scene, the child nodes get saved under the parent (as the parent
	# must own the child nodes). If the owner is not the scene root though, the nodes will NOT
	# show up in the scene tree.
	animated_sprite.set_owner(character_node)

	return largest_frame_dimensions


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
