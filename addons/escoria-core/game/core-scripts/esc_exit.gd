# An item that streamlines exiting scenes
extends ESCItem
class_name ESCExit, "res://addons/escoria-core/design/esc_exit.svg"


# Path to the target scene to change to
export(String, FILE, "*.tscn") var target_scene = ""

# Sound effect to play when changing the scene
export(String, FILE, "*.ogg,*.mp3,*.wav") var switch_sound = ""

# ESC commands kept around for references to their command names.
var _play_snd: PlaySndCommand
var _change_scene: ChangeSceneCommand


func _enter_tree():
	is_exit = true
	player_orients_on_arrival = false


func _ready():
	_play_snd = PlaySndCommand.new()
	_change_scene = ChangeSceneCommand.new()

	call_deferred("_register_event")


# Registers the exit_scene event based on the properties
func _register_event():
	if escoria.object_manager.has(self.global_id) and\
			not escoria.event_manager.EVENT_EXIT_SCENE in escoria.object_manager.get_object(
				self.global_id
			).events:
		var exit_scene_event_script = [
			"%s%s" % [ESCEvent.PREFIX, escoria.event_manager.EVENT_EXIT_SCENE]
		]

		if switch_sound != "":
			exit_scene_event_script.append(
				"%s %s" % [_play_snd.get_command_name(), switch_sound]
			)

		exit_scene_event_script.append(
			"%s %s" % [_change_scene.get_command_name(), target_scene]
		)

		var exit_scene_event = escoria.esc_compiler.compile(
			exit_scene_event_script
		).events[escoria.event_manager.EVENT_EXIT_SCENE]
		escoria.object_manager.get_object(self.global_id)\
				.events[escoria.event_manager.EVENT_EXIT_SCENE] = exit_scene_event
