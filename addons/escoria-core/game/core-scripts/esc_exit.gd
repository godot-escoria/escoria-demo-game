# An item that streamlines exiting scenes
extends ESCItem
class_name ESCExit, "res://addons/escoria-core/design/esc_exit.svg"


# Path to the target scene to change to
export(String, FILE, "*.tscn") var target_scene = ""

# Sound effect to play when changing the scene
export(String, FILE, "*.ogg,*.mp3,*.wav") var switch_sound = ""


func _enter_tree():
	is_exit = true
	player_orients_on_arrival = false


func _ready():
	call_deferred("_register_event")


# Registers the exit_scene event based on the properties
func _register_event():
	if escoria.object_manager.has(self.global_id) and\
			not "exit_scene" in escoria.object_manager.get_object(
				self.global_id
			).events:
		var exit_scene_event_script = [
			":exit_scene",
		]
		
		if switch_sound != "":
			exit_scene_event_script.append(
				"play_snd %s" % switch_sound
			)
		
		exit_scene_event_script.append("change_scene %s" % target_scene)
		
		var exit_scene_event = escoria.esc_compiler.compile(
			exit_scene_event_script
		).events["exit_scene"]
		escoria.object_manager.get_object(self.global_id)\
				.events["exit_scene"] = exit_scene_event
