tool
extends ResourcePreloader
class_name ESCDialogsPlayer

func get_class():
	return "ESCDialogsPlayer"

# This scene is in charge of ALL dialogs management :
# - characters sayings
# - player dialog options panel display/hiding and choices

var path_to_dialog_scenes : String

var is_speaking = false
var dialog_ui = null
var dialog_chooser_ui = null

func _ready():
	if !Engine.is_editor_hint():
		escoria.register_object(self)
	preload_resources(ProjectSettings.get_setting("escoria/ui/dialogs_folder"))

func preload_resources(path : String):
	path_to_dialog_scenes = path

	var dialog_folder := Directory.new()
	if !path_to_dialog_scenes.empty() and dialog_folder.open(path_to_dialog_scenes) == OK:
		dialog_folder.list_dir_begin()
		var file_name = dialog_folder.get_next()
		while file_name != "":
			if !dialog_folder.current_is_dir() and file_name.get_extension() == "tscn":
				var extension = "." + file_name.get_extension()
				var basename = file_name.replace(extension, "")
				
				if !has_resource(basename):
					var file_path = dialog_folder.get_current_dir() + "/" + file_name
					var dialog_scene = load(file_path)
					
					if dialog_scene != null:
						add_resource(basename, dialog_scene)
			file_name = dialog_folder.get_next()
	else:
		escoria.logger.report_errors("dialog_player.gd:preload_resources()", ["An error occurred when trying to access the path: {_}.".format(path)])


func say(character : String, params : Dictionary):
	is_speaking = true
	dialog_ui = get_resource(params.ui).instance()
	get_parent().add_child(dialog_ui)
	dialog_ui.say(character, params)
	

func finish_fast():
	dialog_ui.finish_fast()

# Options:
#    type: (default value "default") the type of dialog menu to use. All types are in the "dd_player" scene.
#    avatar: (default value "default") the avatar to use in the dialog ui.
#    timeout: (default value 0) timeout to select an option. After the time has passed, the "timeout_option" will be selected automatically. If the value is 0, there's no timeout.
#    timeout_option: (default value 0) option selected when timeout is reached.
func start_dialog_choices(answers : Array, options : Array):
	if answers.empty():
		escoria.logger.report_errors("dialog_player.gd:start_dialog_choices()", ["Received answers array was empty."])
	dialog_chooser_ui = get_resource("text_dialog_choice").instance()
	get_parent().add_child(dialog_chooser_ui)
	dialog_chooser_ui.set_answers(answers)

func play_dialog_option_chosen(level_to_run : Array):
#	escoria.esc_runner.finished(context)
	var ev_level = level_to_run
	var ev = esctypes.ESCEvent.new("dialog_choice_done", ev_level, [])
	escoria.esc_runner.add_level(ev, false)
	dialog_chooser_ui.hide()
#	stop()

