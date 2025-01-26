@icon("res://addons/escoria-core/design/esc_exit.svg")
# An ESCExit is a minimal feature node that provides an exit to a room.
#
# For exits that don't require scripts, the ``ESCExit`` node is provided.
# The only things you will need to configure on the node are the
# "target_scene" to change to, and optionally, a "switch
# sound" (the sound to play when changing rooms).
#
# If you want to attach the exit to a script to perform additional actions -
# a cutscene for example - use an ``ESCItem`` with "Is Exit" selected instead.
#
# The game character will automatically walk to an ``ESCLocation`` created as a
# child of an ``ESCExit`` node.
extends ESCItem
class_name ESCExit


# Path to the target scene to change to
@export_file("*.tscn", "*.scn") var target_scene = "" # (String, FILE, "*.tscn")

# Sound effect to play when changing the scene
@export var switch_sound: Resource # (String, FILE, "*.ogg,*.mp3,*.wav")

# ESC commands kept around for references to their command names.
var _play_snd: PlaySndCommand
var _change_scene: ChangeSceneCommand


func _enter_tree():
	is_exit = true


func _ready():
	super._ready()
	_play_snd = PlaySndCommand.new()
	_change_scene = ChangeSceneCommand.new()

	call_deferred("_register_event")


# Registers the exit_scene event based on the properties
func _register_event():
	if escoria.object_manager.has(self.global_id) and\
			not escoria.event_manager.EVENT_EXIT_SCENE in escoria.object_manager.get_object(
				self.global_id
			).events:

		var exit_scene_script_builder: ESCScriptBuilder = ESCScriptBuilder.new()

		exit_scene_script_builder.add_event(escoria.event_manager.EVENT_EXIT_SCENE, [])
		exit_scene_script_builder.begin_block()

#		var exit_scene_event_script = [
#			"%s%s" % [ESCEvent.PREFIX, escoria.event_manager.EVENT_EXIT_SCENE]
#		]

		if switch_sound != null:
			exit_scene_script_builder.add_command(
				_play_snd.get_command_name(),
				switch_sound.resource_path
			)
#			exit_scene_event_script.append(
#				"%s %s" % [_play_snd.get_command_name(), switch_sound]
#			)

		exit_scene_script_builder.add_command(
			_change_scene.get_command_name(),
			target_scene
		)
#		exit_scene_event_script.append(
#			"%s %s" % [_change_scene.get_command_name(), target_scene]
#		)

#		var exit_scene_event = escoria.esc_compiler.compile(
#			exit_scene_event_script,
#			get_class()
#		)
		var exit_scene_event = \
			escoria.esc_compiler.compile(exit_scene_script_builder.build(), get_class()) \
				.events[escoria.event_manager.EVENT_EXIT_SCENE]

		escoria.object_manager.get_object(self.global_id) \
			.events[escoria.event_manager.EVENT_EXIT_SCENE] = exit_scene_event
