tool
extends Control

var test_mode:bool=true	# Set to true to load test data
var source_image:Image
var DestImage:Image
var frame_size:Vector2
var zoom_value:float = 1
var current_animation_speed:int = 5
var direction_selected:String
var direction_requested:String
var current_animation
var anim_metadata=[]
var spritesheet_filename:String
var plugin_reference

func calc_sprite_size() -> void:
	var source_size = source_image.get_size()
	var horiz_size = int(source_size.x / $spritesheet_controls/h_frames_spin_box.value)
	var vert_size = int(source_size.y / $spritesheet_controls/v_frames_spin_box.value)
	frame_size = Vector2(horiz_size, vert_size)
	$spritesheet_controls/original_size_label.text = "Source sprite size = %s" % source_size
	$spritesheet_controls/frame_size_label.text = "Frame size = %s" % frame_size


func _ready() -> void:
	$configuration/node_name/node_name.text = "replace_me"
	$configuration/directions/four_directions.pressed = true
	$configuration/animation/walk_checkbox.pressed = true
	$spritesheet/spritesheet_scroll_container/no_spritesheet_found_sprite.visible = true
	$spritesheet/zoom/zoom_label.text = "Zoom : %sx" % str(zoom_value)
	$preview/anim_preview_sprite.animation = "in_progress"
	$preview/no_anim_found_sprite.visible = true
	create_empty_animations()
	direction_selected = "up"
	activate_direction(direction_selected)
	$store_anim.visible = false
	reset_arrow_colours()

	# Reset GUI controls to initial values
	$spritesheet_controls/start_frame.value = 1
	$spritesheet_controls/end_frame.value = 1
	$spritesheet_controls/h_frames_spin_box.value = 1
	$spritesheet_controls/v_frames_spin_box.value = 1
	$spritesheet_controls/anim_speed_scroll_bar.value = 5
	$spritesheet_controls/anim_speed_label.text="Animation Speed : 5 FPS"
	$spritesheet/current_spritesheet_label.text="No spritesheet loaded."

	# Connect all the signals now the base settings are configured to stop program logic firing during setup
	$spritesheet_controls/h_frames_spin_box.connect("value_changed", self, "controls_on_h_frames_spin_box_value_changed")
	$spritesheet_controls/v_frames_spin_box.connect("value_changed", self, "controls_on_v_frames_spin_box_value_changed")
	$spritesheet_controls/start_frame.connect("value_changed", self, "controls_on_start_frame_value_changed")
	$spritesheet_controls/end_frame.connect("value_changed", self, "controls_on_end_frame_value_changed")
	$spritesheet_controls/anim_speed_scroll_bar.connect("value_changed", self, "controls_on_anim_speed_scroll_bar_value_changed")
	if test_mode:
		setup_test_data()


func setup_test_data() -> void:
# Load test data - primarily for testing export, but also for testing general functionality.
# Different spritesheets, mirroring settings, frame counts, and speeds are used deliberately.
	load_file("res://addons/escoria-player-creator/graphics/mark-animtest.png")

	var start_frames=[15, 10, 7, 10, 12, 14, 1, 14, 12, 3, 1, 1]
	var end_frames=[17, 14, 9, 14, 13, 18, 3, 18, 12, 3, 1, 22]
	var mirrored=[0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0,]
	var sourcefile=[0, 0, 0, 0, 2, 2, 1, 2, 2, 0, 0, 0]
	var fps=[3, 3, 1, 3, 3, 3, 1, 3, 3, 3, 1, 3]
	for loop in range(12):

		if sourcefile[loop] == 0:
			anim_metadata[loop * 2]["spritesheet_source_file"] = "res://addons/escoria-player-creator/graphics/mark-animtest.png"
			anim_metadata[loop * 2]["spritesheet_frames_horiz"] = 8
			anim_metadata[loop * 2]["spritesheet_frames_vert"] = 3
		elif sourcefile[loop] == 1:
			anim_metadata[loop * 2]["spritesheet_source_file"] = "res://game/characters/mark/png/mark_talk_down.png"
			anim_metadata[loop * 2]["spritesheet_frames_horiz"] = 3
			anim_metadata[loop * 2]["spritesheet_frames_vert"] = 1
		else:
			anim_metadata[loop * 2]["spritesheet_source_file"] = "res://game/characters/mark/png/markjester_talk.png"
			anim_metadata[loop * 2]["spritesheet_frames_horiz"] = 21
			anim_metadata[loop * 2]["spritesheet_frames_vert"] = 1

		anim_metadata[loop * 2]["spritesheet_first_frame"] = start_frames[loop]
		anim_metadata[loop * 2]["spritesheet_last_frame"] = end_frames[loop]
		anim_metadata[loop * 2]["speed"] = fps[loop]
		if mirrored[loop] == 0:
			anim_metadata[loop * 2]["is_mirror"] = ""
		else:
			anim_metadata[loop * 2]["is_mirror"] = "true"
	$spritesheet/spritesheet_scroll_container/no_spritesheet_found_sprite.visible = false
	reset_arrow_colours()


func create_empty_animations() -> void:
# Animations are stored as metadata in an array. This creates the initial empty array.
# The preview animation ("in_progress") is the only sprite animation created prior to the final export.
	var sframes = SpriteFrames.new()

	var metadata_dict = {
		"anim_name": "tbc",
		"spritesheet_source_file": "tbc",
		"spritesheet_frames_horiz": -1,
		"spritesheet_frames_vert": -1,
		"spritesheet_first_frame": -1,
		"spritesheet_last_frame": -1,
		"speed": 30,
		"is_mirror": ""
		}
	var local_dict
	for typeloop in ["walk", "talk", "idle"]:
		for dirloop in ["up", "upright", "right", "downright", "down", "downleft", "left", "upleft"]:
			local_dict = metadata_dict.duplicate()
			local_dict["anim_name"] = "%s_%s" % [typeloop, dirloop]
			anim_metadata.append(local_dict)
	sframes.add_animation("in_progress")
	$preview/anim_preview_sprite.frames = sframes


func load_file(file_to_load, read_settings_from_metadata:bool = false, metadata_frame:int = 0) -> void:
# Loads a spritesheet and calculates the size of each sprite frame if loading a spritesheet
# to show a previously stored animation.
	var texture = ImageTexture.new()
	source_image = Image.new()
	var errorval = source_image.load(file_to_load)
	if errorval:
		assert(false, "Error loading file %s" % str(file_to_load))
	texture.create_from_image(source_image)
	texture.set_flags(2)
	$spritesheet/spritesheet_scroll_container/control/spritesheet_sprite.texture = texture
	frame_size = source_image.get_size()
	if read_settings_from_metadata:
		$spritesheet_controls/h_frames_spin_box.value = anim_metadata[metadata_frame]["spritesheet_frames_horiz"]
		$spritesheet_controls/v_frames_spin_box.value = anim_metadata[metadata_frame]["spritesheet_frames_vert"]
	else:
		$spritesheet_controls/h_frames_spin_box.value = 1
		$spritesheet_controls/v_frames_spin_box.value = 1
	calc_sprite_size()
	$spritesheet/current_spritesheet_label.text = file_to_load
	draw_frame_outlines()
	spritesheet_on_zoom_reset_button_pressed()
	$spritesheet/spritesheet_scroll_container/control.rect_min_size = source_image.get_size() * zoom_value	# Make scroll bars appear if necessary


func draw_frame_outlines() -> void:
# Draws an outline on the spritesheet to show which frames are included in the current animation
	check_frame_limits()
	$spritesheet/spritesheet_scroll_container/control/frame_rectangles.rect_scale.x = zoom_value
	$spritesheet/spritesheet_scroll_container/control/frame_rectangles.rect_scale.y = zoom_value
	$spritesheet/spritesheet_scroll_container/control/frame_rectangles.total_num_columns = $spritesheet_controls/h_frames_spin_box.value
	$spritesheet/spritesheet_scroll_container/control/frame_rectangles.start_cell = $spritesheet_controls/start_frame.value
	$spritesheet/spritesheet_scroll_container/control/frame_rectangles.end_cell = $spritesheet_controls/end_frame.value
	$spritesheet/spritesheet_scroll_container/control/frame_rectangles.cell_size = frame_size
	$spritesheet/spritesheet_scroll_container/control/frame_rectangles.update()


func calc_frame_coords(Frame:int) -> Vector2:
# When given a frame number, this calculates the pixel coordinates that frame in the spritesheet
# based on the number of horizontal/vertical frames configured for this spritesheet
	var column = (Frame - 1) % int($spritesheet_controls/h_frames_spin_box.value) * frame_size.x
	var row = int((Frame - 1) / $spritesheet_controls/h_frames_spin_box.value) * frame_size.y
	return Vector2(column, row)


func store_animation(animation_to_store:String) -> void:
# Updates the animation metadata to store the changed / new settings for a particular animation
	var texture
	var RectLocation
	var FrameBeingCopied = Image.new()
	var FrameCounter:int = 0

	var metadata_dict = {
		"anim_name": animation_to_store,
		"spritesheet_source_file": $spritesheet/current_spritesheet_label.text,
		"spritesheet_frames_horiz": $spritesheet_controls/h_frames_spin_box.value,
		"spritesheet_frames_vert": $spritesheet_controls/v_frames_spin_box.value,
		"spritesheet_first_frame": $spritesheet_controls/start_frame.value,
		"spritesheet_last_frame": $spritesheet_controls/end_frame.value,
		"speed": $spritesheet_controls/anim_speed_scroll_bar.value,
		"is_mirror": ""
		}
	if $configuration/animation/mirror_checkbox.pressed == true:
		metadata_dict["is_mirror"] = true
	anim_metadata[get_metadata_array_offset()] = metadata_dict


func mirror_animation(source:String, dest:String) -> void:
# Updates the metadata to mirror animation "source" to animation "dest"
# The "source" animation is the animation that really exists as sprite frames
# in the animated sprite
	var texture
	var RectLocation
	var FrameBeingCopied = Image.new()
	var FrameCounter:int = 0
#
	var metadata_source_offset = get_metadata_array_offset(source)
	var metadata_dest_offset = get_metadata_array_offset(dest)
	var dest_anim_name="%s_%s" % [return_current_animation_type(), dest]
	var metadata_dict = {
		"anim_name": dest_anim_name,
		"spritesheet_source_file": anim_metadata[metadata_source_offset]["spritesheet_source_file"],
		"spritesheet_frames_horiz": anim_metadata[metadata_source_offset]["spritesheet_frames_horiz"],
		"spritesheet_frames_vert": anim_metadata[metadata_source_offset]["spritesheet_frames_vert"],
		"spritesheet_first_frame": anim_metadata[metadata_source_offset]["spritesheet_first_frame"],
		"spritesheet_last_frame": anim_metadata[metadata_source_offset]["spritesheet_last_frame"],
		"speed": anim_metadata[metadata_source_offset]["speed"],
		"is_mirror": "true"
		}
	anim_metadata[metadata_dest_offset] = metadata_dict
	reset_arrow_colours()


func preview_update() -> void:
# Creates the "in_progress" animation which is shown in the UI as the animation preview based
# on the currently selected settings.
# A mirrored animation (frames in reverse order and sprites horizontally flipped) is generated here
# for the purpose of the preview but isn't generated in the final export as it relies on ESCPlayer's
# is_mirrored setting.
	check_frame_limits()
	var anim_name="%s_%s" % [return_current_animation_type(), direction_selected]
	var offset = get_metadata_array_offset()
	var generate_mirror = false
	if $configuration/animation/mirror_checkbox.pressed == true:
		generate_mirror = true

	var texture
	var rect_location
	var frame_being_copied = Image.new()
	var frame_counter:int = 0

	$preview/anim_preview_sprite.frames.clear("in_progress")
	frame_being_copied.create(frame_size.x, frame_size.y, false, source_image.get_format())
	for loop in range($spritesheet_controls/end_frame.value - $spritesheet_controls/start_frame.value + 1):
		texture = ImageTexture.new()
		if generate_mirror:
			rect_location = calc_frame_coords($spritesheet_controls/end_frame.value - loop)
		else:
			rect_location = calc_frame_coords($spritesheet_controls/start_frame.value + loop)
		frame_being_copied.blit_rect(source_image, Rect2(rect_location, Vector2(frame_size.x, frame_size.y)), Vector2(0, 0))
		if generate_mirror:
			frame_being_copied.flip_x()
		texture.create_from_image(frame_being_copied)
		texture.set_flags(2)	# Remove the image filter to make pixel correct graphics
		$preview/anim_preview_sprite.frames.add_frame ("in_progress", texture, frame_counter )
		frame_counter += 1
	$preview/no_anim_found_sprite.visible = false

	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	var preview_scale = Vector2(1,1)
	preview_scale.x = $preview/anim_preview_background.rect_size.x / frame_size.x
	preview_scale.y = $preview/anim_preview_background.rect_size.y / frame_size.y
	if preview_scale.y > preview_scale.x:
		$preview/anim_preview_sprite.scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		$preview/anim_preview_sprite.scale = Vector2(preview_scale.y, preview_scale.y)


func check_frame_limits():
# Ensure that the spritesheet settings are valid
	var max_frame = $spritesheet_controls/h_frames_spin_box.value * $spritesheet_controls/v_frames_spin_box.value
	if $spritesheet_controls/start_frame.value > max_frame:
		$spritesheet_controls/start_frame.value = max_frame
	if $spritesheet_controls/end_frame.value > max_frame:
		$spritesheet_controls/end_frame.value = max_frame
	if $spritesheet_controls/start_frame.value > $spritesheet_controls/end_frame.value:
		$spritesheet_controls/end_frame.value = $spritesheet_controls/start_frame.value


func check_if_controls_have_changed():
# If any spritesheet settings have changed, display the "store animation" button to save the changes.
# If the values are manually reset after a change to the previously stored settings, the button will disappear.
	if ! $spritesheet_controls/anim_speed_scroll_bar.value == anim_metadata[get_metadata_array_offset()]["speed"]:
		$store_anim.visible = true
		return
	if ! $spritesheet_controls/start_frame.value == anim_metadata[get_metadata_array_offset()]["spritesheet_first_frame"]:
		$store_anim.visible = true
		return
	if ! $spritesheet_controls/end_frame.value == anim_metadata[get_metadata_array_offset()]["spritesheet_last_frame"]:
		$store_anim.visible = true
		return
	if ! $spritesheet_controls/h_frames_spin_box.value == anim_metadata[get_metadata_array_offset()]["spritesheet_frames_horiz"]:
		$store_anim.visible = true
		return
	if ! $spritesheet_controls/v_frames_spin_box.value == anim_metadata[get_metadata_array_offset()]["spritesheet_frames_vert"]:
		$store_anim.visible = true
		return
	$store_anim.visible = false


func has_spritesheet_been_loaded() -> bool:
# If the user tries to change settings before they've loaded a spritesheet, this will display
# a warning window instead of letting them change settings.
	if source_image == null:
		$error_windows/generic_error_window.dialog_text = \
		"Please load a spritesheet to begin."
		$error_windows/generic_error_window.popup()
		return false
	return true


func animation_on_walk_checkbox_pressed() -> void:
# If the walk button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean  that none of walk/talk/idle were selected.
	if $configuration/animation/walk_checkbox.pressed == false:
		$configuration/animation/walk_checkbox.pressed = true
	$configuration/animation/idle_checkbox.pressed = false
	$configuration/animation/talk_checkbox.pressed = false
	reset_arrow_colours()


func animation_on_talk_checkbox_pressed() -> void:
# If the talk button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean  that none of walk/talk/idle were selected.
	if $configuration/animation/talk_checkbox.pressed == false:
		$configuration/animation/talk_checkbox.pressed = true
	$configuration/animation/idle_checkbox.pressed = false
	$configuration/animation/walk_checkbox.pressed = false
	reset_arrow_colours()


func animation_on_idle_checkbox_pressed() -> void:
# If the idle button is selected, unselect the other buttons.
# If this option was already the selected option, reselect it rather than letting the
# user disable it (which would mean  that none of walk/talk/idle were selected.
	if $configuration/animation/idle_checkbox.pressed == false:
		$configuration/animation/idle_checkbox.pressed = true
	$configuration/animation/walk_checkbox.pressed = false
	$configuration/animation/talk_checkbox.pressed = false
	reset_arrow_colours()


func animation_on_dir_up_pressed() -> void:
	check_activate_direction("up")


func animation_on_dir_right_pressed() -> void:
# Runs when the direction arrow is clicked
	check_activate_direction("right")


func animation_on_dir_left_pressed() -> void:
# Runs when the direction arrow is clicked
	check_activate_direction("left")


func animation_on_dir_down_pressed() -> void:
# Runs when the direction arrow is clicked
	check_activate_direction("down")


func animation_on_dir_downright_pressed() -> void:
# Runs when the direction arrow is clicked
	check_activate_direction("downright")


func animation_on_dir_downleft_pressed() -> void:
# Runs when the direction arrow is clicked
	check_activate_direction("downleft")


func animation_on_dir_upright_pressed() -> void:
# Runs when the direction arrow is clicked
	check_activate_direction("upright")


func animation_on_dir_upleft_pressed() -> void:
# Runs when the direction arrow is clicked
	check_activate_direction("upleft")


func animation_on_mirror_checkbox_toggled(button_pressed: bool) -> void:
# If the user tries to mirror an animation, ensure they're not trying to mirror an already
# mirrored direction, and that the direction they're trying to mirror has been created.
	var opp_dir = find_opposite_direction(direction_selected)
	var opp_anim_name="%s_%s" % [return_current_animation_type(), opp_dir]
	if button_pressed == true:
		if anim_metadata[get_metadata_array_offset(opp_dir)]["is_mirror"] == "true":
			$error_windows/generic_error_window.dialog_text = \
				"You cant mirror a direction that is already mirrored."
			$error_windows/generic_error_window.popup()
			$configuration/animation/mirror_checkbox.pressed = false
			return

		if anim_metadata[get_metadata_array_offset(opp_dir)]["spritesheet_first_frame"] == -1:
			$error_windows/generic_error_window.dialog_text = \
				"You cant mirror an animation that hasn't been set up."
			$error_windows/generic_error_window.popup()
			$configuration/animation/mirror_checkbox.pressed = false
			return

		mirror_animation(opp_dir, direction_selected)
		preview_update()
	else:
		anim_metadata[get_metadata_array_offset(opp_dir)]["is_mirror"] = ""


func controls_on_anim_speed_scroll_bar_value_changed(value: float) -> void:
# When the animation speed has been changed, update the speed and label
	if ! has_spritesheet_been_loaded():
		return
	current_animation_speed = int(value)
	check_if_controls_have_changed()
	$spritesheet_controls/anim_speed_label.text = "Animation Speed : %s FPS" % value
	$preview/anim_preview_sprite.frames.set_animation_speed("in_progress", value)
	preview_update()


func controls_on_start_frame_value_changed(value: float) -> void:
# When the first animation frame setting is changed, update the animation preview appropriately
	if ! has_spritesheet_been_loaded():
		return
	$preview/no_anim_found_sprite.visible = false
	check_if_controls_have_changed()
	draw_frame_outlines()
	preview_update()


func controls_on_end_frame_value_changed(value: float) -> void:
# When the last animation frame setting is changed, update the animation preview appropriately
	if ! has_spritesheet_been_loaded():
		return
	$preview/no_anim_found_sprite.visible = false
	check_if_controls_have_changed()
	draw_frame_outlines()
	preview_update()


func controls_on_h_frames_spin_box_value_changed(value: float) -> void:
# When the number of horizontal frames in the spritesheet setting is changed,
# update the animation preview appropriately
	if ! has_spritesheet_been_loaded():
		return
	$preview/no_anim_found_sprite.visible = false
	check_if_controls_have_changed()
	calc_sprite_size()
	draw_frame_outlines()
	preview_update()


func controls_on_v_frames_spin_box_value_changed(value: float) -> void:
# When the number of vertical frames in the spritesheet setting is changed,
# update the animation preview appropriately
	if ! has_spritesheet_been_loaded():
		return
	$preview/no_anim_found_sprite.visible = false
	check_if_controls_have_changed()
	calc_sprite_size()
	draw_frame_outlines()
	preview_update()


func controls_on_FileDialog_file_selected(path: String) -> void:
# Load a spritesheet when selected in the file browser
	$spritesheet/spritesheet_scroll_container/no_spritesheet_found_sprite.visible = false
	load_file(path)


func spritesheet_on_export_button_pressed() -> void:
# Check all animations have been created when the user wants to export the ESCPlayer
	var missing_walk_animations:int = 0
	var missing_talk_animations:int = 0
	var missing_idle_animations:int = 0
	var anim_name

	var dirnames = []
	if $configuration/directions/four_directions.pressed == true:
		dirnames = ["up", "right", "down", "left"]
	else:
		dirnames = ["up", "upright", "right", "downright", "down", "downleft", "left", "upleft"]

	for dirloop in dirnames:
		anim_name="%s_%s" % ["walk", dirloop]
		if anim_metadata[get_metadata_array_offset(dirloop, "walk")]["spritesheet_first_frame"] == -1:
				missing_walk_animations += 1
		anim_name="%s_%s" % ["talk", dirloop]
		if anim_metadata[get_metadata_array_offset(dirloop, "talk")]["spritesheet_first_frame"] == -1:
				missing_talk_animations += 1
		anim_name="%s_%s" % ["idle", dirloop]
		if anim_metadata[get_metadata_array_offset(dirloop, "idle")]["spritesheet_first_frame"] == -1:
				missing_idle_animations += 1

	if missing_idle_animations + missing_talk_animations + missing_walk_animations > 0:
		$error_windows/generic_error_window.dialog_text = \
			"One or more animations are not configured.\nPlease ensure all arrows are green for\nwalk, talk, and idle animations.\n\n"
		if missing_walk_animations:
			$error_windows/generic_error_window.dialog_text += \
				"%s walk animations not configured.\n" % missing_walk_animations
		if missing_talk_animations:
			$error_windows/generic_error_window.dialog_text += \
				"%s talk animations not configured.\n" % missing_talk_animations
		if missing_idle_animations:
			$error_windows/generic_error_window.dialog_text += \
				"%s idle animations not configured." % missing_idle_animations
		$error_windows/generic_error_window.popup()
		return
	export_escplayer()


func spritesheet_on_zoom_scrollbar_value_changed(value: float) -> void:
# Update the spritesheet zoom and scrollbars
	if ! has_spritesheet_been_loaded():
		return
	zoom_value = stepify(value, 0.1)
	$spritesheet/zoom/zoom_label.text = "Zoom : %sx" % str(zoom_value)
	$spritesheet/spritesheet_scroll_container/control/spritesheet_sprite.scale.x = zoom_value
	$spritesheet/spritesheet_scroll_container/control/spritesheet_sprite.scale.y = zoom_value
	$spritesheet/spritesheet_scroll_container/control.rect_min_size = source_image.get_size() * zoom_value
	draw_frame_outlines()


func spritesheet_on_load_spritesheet_button_pressed() -> void:
# Show the file manager when the load spritesheet button is pressed
	$spritesheet_controls/FileDialog.popup()


func spritesheet_on_zoom_reset_button_pressed() -> void:
# Reset zoom settings when the reset button is pushed. Also called when a new
# spritesheet is loaded.
	if ! has_spritesheet_been_loaded():
		return
	$spritesheet/zoom/zoom_scrollbar.value = 1
	$spritesheet/spritesheet_scroll_container.scroll_horizontal = 0
	$spritesheet/spritesheet_scroll_container.scroll_vertical = 0


func nodename_on_node_name_text_changed(new_text: String) -> void:
# If the node name is changed, update the global_id to match.
# NOTE : Updating the global_id doesn't update the nodename, allowing them to be different.
	$configuration/node_name/global_id.text = new_text


func directions_on_eight_directions_pressed() -> void:
# If 8 directions was already selected, don't let it be unselected.
# If 4 directions was selected, unselect it.
	if $configuration/directions/eight_directions.pressed == false:
		$configuration/directions/eight_directions.pressed = true	# Don't let them untick all boxes
	$configuration/directions/four_directions.pressed = false
	reset_arrow_colours()


func directions_on_four_directions_pressed() -> void:
# If 4 directions was already selected, don't let it be unselected.
# If 8 directions was selected, unselect it. Also if the previously selected direction was
# a diagonal, reset the selection to up as the diagonal is no longer valid.
	if $configuration/directions/four_directions.pressed == false:
		$configuration/directions/four_directions.pressed = true	# Don't let them untick all boxes
	else:
		var dirlist = ["up","left","right","down"]
		if ! direction_selected in dirlist:	# current direction is diagonal
			direction_selected = "up"
			activate_direction("up")
	$configuration/directions/eight_directions.pressed = false
	reset_arrow_colours()


func return_current_animation_type() -> String:
# Returns the currently selected animation type
	if $configuration/animation/walk_checkbox.pressed == true:
		return("walk")
	elif $configuration/animation/talk_checkbox.pressed == true:
		return("talk")
	elif $configuration/animation/idle_checkbox.pressed == true:
		return("idle")
	else:
		assert(false, "No animation type selected.")
		return("false")	# Godot complains if this branch doesnt return a value


func check_activate_direction(direction) -> void:
# Runs whenever a direction arrow is clicked. If the store button is visible (i.e. the settings
# for the sprite frames have changed since they were last stored) the selected direction isn't
# changed and a confirmation window is shown instead.
	direction_requested = direction
	if $store_anim.visible == true:
		var button_name = "set_dir_%s" % direction
		$configuration/animation.get_node(button_name).pressed = false
		$configuration/animation.get_node("%s%s" % ["un", button_name]).pressed = false
		$error_windows/unstored_changes_window.popup()
	else:
		activate_direction(direction)


func activate_direction(direction) -> void:
# Change the selected direction. This clears the selected direction arrow and mirror settings.
# If the selected direction has an animation, it will be displayed, if not, the "no animation"
# graphic will be displayed in the preview window.
# Spritesheet control values are set based on the direction chosen (if it had a previous animation)
# If it used a different spritesheet, that will be loaded.
	# We have to temporarily disable the signal. If we don't do this, when you change direction to
	# up or down, it will removing the tick from the checkbox (as those directions aren't mirrored)
	# but will then try to run the logic to remove mirroring from the directions that don't support
	# it.
	if $configuration/animation/mirror_checkbox.is_connected("toggled", self, "animation_on_mirror_checkbox_toggled"):
		$configuration/animation/mirror_checkbox.disconnect("toggled", self, "animation_on_mirror_checkbox_toggled")
	direction_selected = direction
	var anim_type = return_current_animation_type()

	var arrows = get_tree().get_nodes_in_group("direction_buttons")
	for loop in arrows:
		loop.pressed = false

	var anim_name = "%s_%s" % [anim_type, direction]
	if direction == "up" or direction == "down":
		$configuration/animation/mirror_checkbox.visible = false
	else:
		$configuration/animation/mirror_checkbox.visible = true
		$configuration/animation/mirror_checkbox.pressed = false

	if anim_metadata[get_metadata_array_offset()]["spritesheet_first_frame"] == -1:
		$configuration/animation.get_node("unset_dir_%s" % direction).pressed = true
		$preview/no_anim_found_sprite.visible = true
	else:
		$configuration/animation.get_node("set_dir_%s" % direction).pressed = true

		var metadata = anim_metadata[get_metadata_array_offset()]


		if ! metadata["anim_name"] == anim_name:
			assert(false, "Anim %s expected in metadata array. Found %s" % [anim_name, metadata["anim_name"]])

		if ! metadata["spritesheet_source_file"] == $spritesheet/current_spritesheet_label.text:
			load_file(metadata["spritesheet_source_file"])

		$spritesheet_controls/h_frames_spin_box.value = metadata["spritesheet_frames_horiz"]
		$spritesheet_controls/v_frames_spin_box.value = metadata["spritesheet_frames_vert"]
		$spritesheet_controls/start_frame.value = metadata["spritesheet_first_frame"]
		$spritesheet_controls/end_frame.value = metadata["spritesheet_last_frame"]
		$spritesheet_controls/anim_speed_scroll_bar.value = metadata["speed"]
		$configuration/animation/mirror_checkbox.pressed = bool(metadata["is_mirror"])
		preview_update()
		# Restart animation otherwise it will first complete all the frames before changing to the new animation
		$preview/anim_preview_sprite.playing = false
		$preview/anim_preview_sprite.playing = true

	$configuration/animation/mirror_checkbox.connect("toggled", self, "animation_on_mirror_checkbox_toggled")


func store_on_anim_store_button_pressed() -> void:
# Store the metadata for the animation changes for the current direction
	$store_anim.visible = false
	var anim_type = return_current_animation_type()
	store_animation("%s_%s" % [anim_type, direction_selected])
	reset_arrow_colours()


func get_metadata_array_offset(dir_to_retrieve = "default", anim_type = "default") -> int:
# Based on the type of animation and direction, find its array position in the metadata array.
	if anim_type == "default":
		anim_type = return_current_animation_type()
	var offset = 0
	if anim_type == "talk":
		offset = 8
	elif anim_type == "idle":
		offset = 16
	if dir_to_retrieve == "default":
		dir_to_retrieve = direction_selected
	match dir_to_retrieve:
		"up" : return offset
		"upright" : return (offset + 1)
		"right" : return (offset + 2)
		"downright" : return (offset + 3)
		"down" : return (offset + 4)
		"downleft" : return (offset + 5)
		"left" : return (offset + 6)
		"upleft" : return (offset + 7)
	assert(false, "Need a return here to keep Godot happy. This case should never happen though.")
	return -1


# Using both set and unset buttons (instead of changing the texture to a different colour) as
# updating the direction arrow sprite was causing issues due to Godot storing the
# sprite by reference rather than by value. It was easier to duplicate the sprites/buttons.
func reset_arrow_colours() -> void:
	var current_animation_type = return_current_animation_type()
	var current_animation_name

	for loop in ["up", "upright", "right", "downright", "down", "downleft", "left", "upleft"]:
		current_animation_name = "%s_%s" % [current_animation_type, loop]
		if anim_metadata[get_metadata_array_offset(loop)]["spritesheet_first_frame"] > -1:
			$configuration/animation.get_node("set_dir_%s" % loop).visible = true
			$configuration/animation.get_node("unset_dir_%s" % loop).visible = false
		else:
			$configuration/animation.get_node("set_dir_%s" % loop).visible = false
			$configuration/animation.get_node("unset_dir_%s" % loop).visible = true
	if $configuration/directions/four_directions.pressed == true:
		var arrows = get_tree().get_nodes_in_group("8_direction_buttons")
		for loop in arrows:
			loop.visible = false
	var dirlist = ["up","left","right","down"]
	if ! direction_selected in dirlist:	# current direction is diagonal
		direction_selected = "up"
		activate_direction("up")
	activate_direction(direction_selected)	# This works when you change between animation types
	# eg. walk and talk - to ensure that the arrow will get changed back from selected with stored
	# animation to selected with unstored animation if needs be. It also resets the preview.


func unstored_warning_on_commit_button_pressed() -> void:
# If the user tries to change direction without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to save the changes, then will update
# the interface to select the new direction.
	$error_windows/unstored_changes_window.visible = false
	$store_anim.visible = false
	var anim_type = return_current_animation_type()
	store_animation("%s_%s" % [anim_type, direction_selected])
	reset_arrow_colours()
	activate_direction(direction_requested)


func unstored_warning_on_lose_button_pressed() -> void:
# If the user tries to change direction without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to lose the changes, then will update
# the interface to select the new direction.
	$error_windows/unstored_changes_window.visible = false
	$store_anim.visible = false
	activate_direction(direction_requested)


func unstored_warning_on_cancel_button_pressed() -> void:
# If the user tries to change direction without commiting first, a window will appear to
# confirm what they want to do.
# The button associated with this function chooses to cancel the request to change direction
# and let the user continue to edit the current animation.
	$error_windows/unstored_changes_window.visible = false


func find_opposite_direction(direction:String) -> String:
# Returns the opposite direction for mirroring animations
	match direction:
		"upright" : return("upleft")
		"right" : return("left")
		"downright" : return("downleft")
		"downleft" : return("downright")
		"left" : return("right")
		"upleft" : return("upright")
	assert(false, "This should never happen : direction = %s" % direction)
	return("broken")


func export_escplayer() -> void:
# Creates an ESCPlayer node based on the settings configured in the wizard.
# It will save it as a scene (named based on the name provided in the GUI text box)
# and open it in the Godot editor - which is why this utility has to run as a plugin.
# This will also create an ESCDialogue position, and a collision box. The collision box will
# be sized based on the widest and tallest frames encountered during export (note that the
# widest/tallest frame settings do not necessarily come from the same animation frame but are
# from all the animation frames.
	var num_directions
	var start_angle_array
	var angle_size
	var dirnames

	if $configuration/directions/eight_directions.pressed == true:
		num_directions = 8
	else:
		num_directions = 4

	var new_character = ESCPlayer.new()
	new_character.name = $configuration/node_name/node_name.text

	if $configuration/node_name/global_id.text == null:
		new_character.global_id = new_character.name
	new_character.global_id = $configuration/node_name/global_id.text
	var animations_resource = ESCAnimationResource.new()

	# This is necessary to avoid a Godot bug with appending to one array
	# appending to all arrays in the same class.
	animations_resource.dir_angles = []
	animations_resource.directions = []
	animations_resource.idles = []
	animations_resource.speaks = []

	if $configuration/directions/four_directions.pressed == true:
		num_directions = 4
		start_angle_array = [315 ,45, 135, 225]
		angle_size = 90
		dirnames = ["up", "right", "down", "left"]
	else:
		num_directions = 8
		start_angle_array = [338, 22, 69, 114, 159, 204, 249, 294]
		angle_size = 45
		dirnames = ["up", "upright", "right", "downright", "down", "downleft", "left", "upleft"]

	for loop in range(num_directions):
			# Need to create new objects here each time in order to avoid having multiple references
			# to the same objects.
			var dir_angle = ESCDirectionAngle.new()
			var anim_details_walk = ESCAnimationName.new()
			var anim_details_talk = ESCAnimationName.new()
			var anim_details_idle = ESCAnimationName.new()

			dir_angle.angle_start = start_angle_array[loop]
			dir_angle.angle_size = angle_size
			animations_resource.dir_angles.append(dir_angle)
			print("dir_angles array = "+str(animations_resource.dir_angles))
			print("directions array = "+str(animations_resource.directions))

			var anim_name = "walk_%s" % dirnames[loop]
			anim_details_walk.animation = anim_name
			if anim_metadata[get_metadata_array_offset(dirnames[loop], "walk")]["is_mirror"]:
					anim_details_walk.mirrored = true
					anim_details_walk.animation = "walk_%s" % find_opposite_direction(dirnames[loop])
			else:
					anim_details_walk.mirrored = false
			animations_resource.directions.append(anim_details_walk)
			print("dir_angles array = "+str(animations_resource.dir_angles))
			print("directions array = "+str(animations_resource.directions))
			print("Size of dir_angles array = " + str(animations_resource.dir_angles.size()))

			anim_name = "talk_%s" % dirnames[loop]
			anim_details_talk.animation = anim_name
			if anim_metadata[get_metadata_array_offset(dirnames[loop], "talk")]["is_mirror"]:
					anim_details_talk.mirrored = true
					anim_details_talk.animation = "talk_%s" % find_opposite_direction(dirnames[loop])
			else:
					anim_details_talk.mirrored = false
			animations_resource.directions.append(anim_details_talk)

			anim_name = "idle_%s" % dirnames[loop]
			anim_details_idle.animation = anim_name
			if anim_metadata[get_metadata_array_offset(dirnames[loop], "idle")]["is_mirror"]:
					anim_details_idle.mirrored = true
					anim_details_idle.animation = "talk_%s" % find_opposite_direction(dirnames[loop])
			else:
					anim_details_idle.mirrored = false
			animations_resource.directions.append(anim_details_idle)

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
	ResourceSaver.save("res://%s.tscn" % $configuration/node_name/node_name.text, packed_scene)
	# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript
	ResourceSaver.save("res://%s.tscn" % $configuration/node_name/node_name.text, packed_scene, ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

	new_character.queue_free()
	get_tree().edited_scene_root.get_node(new_character.name).queue_free()
	plugin_reference.open_scene("res://%s.tscn" % $configuration/node_name/node_name.text)


func export_generate_animations(character_node, num_directions) -> Vector2:
# When exporting the ESCPlayer, this function loads the relevant spritesheets based on the
# animation metadata, and copies the frames to the relevant animations within the animatedsprite
# attached to the ESCPlayer.
	var direction_names
	var loaded_spritesheet:String
	var largest_frame_dimensions:Vector2 = Vector2(0,0)
	var sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	if num_directions == 4:
		direction_names = ["up", "right", "down", "left"]
	else:
		direction_names = ["up", "upright", "right", "downright", "down", "downleft", "left", "upleft"]
	for animtype in ["walk", "talk", "idle"]:
		print("Animtype = "+animtype)
		for anim_dir in direction_names:
			var anim_name="%s_%s" % [animtype, anim_dir]
			var metadata = anim_metadata[get_metadata_array_offset(anim_dir, animtype)]
			print ("is mirror = " + str(bool(metadata["is_mirror"])))
			if bool(metadata["is_mirror"]):
				continue

			var texture
			var rect_location
			var frame_being_copied = Image.new()
			var frame_counter:int = 0
			sprite_frames.add_animation(anim_name)

			if ! metadata["spritesheet_source_file"] == loaded_spritesheet:
				load_file(metadata["spritesheet_source_file"], true, get_metadata_array_offset(anim_dir, animtype))
				loaded_spritesheet = metadata["spritesheet_source_file"]
				if frame_size.x > largest_frame_dimensions.x:
					largest_frame_dimensions.x = frame_size.x
				if frame_size.y > largest_frame_dimensions.y:
					largest_frame_dimensions.y = frame_size.y

			frame_being_copied.create(frame_size.x, frame_size.y, false, source_image.get_format())
			for loop in range(metadata["spritesheet_last_frame"] - metadata["spritesheet_first_frame"]  + 1):
				print("Frame export : "+str(frame_counter))
				texture = ImageTexture.new()
				rect_location = calc_frame_coords(metadata["spritesheet_first_frame"] + loop)
				frame_being_copied.blit_rect(source_image, Rect2(rect_location, Vector2(frame_size.x, frame_size.y)), Vector2(0, 0))
				texture.create_from_image(frame_being_copied)
				texture.set_flags(2)	# Remove "filter" flag so it's pixel perfect
				sprite_frames.add_frame (anim_name, texture, frame_counter )
				sprite_frames.set_animation_speed(anim_name, metadata["speed"])
				frame_counter += 1

	var animated_sprite = AnimatedSprite.new()
	animated_sprite.frames = sprite_frames
	character_node.add_child(animated_sprite)
	# Making the owner "character_node" rather than "get_tree().edited_scene_root" means that
	# when saving as a packed scene, the child nodes get saved under the parent (as the parent
	# must own the child nodes). If the owner is not the scene root though, the nodes will NOT
	# show up in the scene tree.
	animated_sprite.set_owner(character_node)
	return(largest_frame_dimensions)




