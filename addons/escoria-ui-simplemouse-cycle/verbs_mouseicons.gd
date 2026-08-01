extends Control


## Player-cycleable verbs only (excludes exit/wait/dialog_choice cursor states).
const CYCLEABLE_VERBS: Array[String] = [
	"walk",
	"look",
	"pickup",
	"use",
	"talk",
]

## Cursor states that are visual-only (do not change the current ASHES verb).
const VISUAL_ONLY_CURSORS: Array[String] = [
	"wait",
	SimpleMouseCycleUISettings.DIALOG_CHOICE_CURSOR_NAME,
]


var current_cursor_id: int = 0
@onready var cursors: Array = $actions.get_children()

@onready var action_manually_changed = false

## Index into CYCLEABLE_VERBS for right-click / mousewheel cycling.
var _cycle_index: int = 0


func _ready():
	if !Engine.is_editor_hint():
		_cycle_index = 0
		set_by_name("walk")
		set_process(false)


func _process(_delta):
	$mouse_position.global_position = get_global_mouse_position()


func iterate_actions_cursor(direction: int):
	_cycle_index = (_cycle_index + direction) % CYCLEABLE_VERBS.size()
	if _cycle_index < 0:
		_cycle_index = CYCLEABLE_VERBS.size() - 1
	set_by_name(CYCLEABLE_VERBS[_cycle_index])
	if $mouse_position/tool.texture != null:
		clear_tool_texture()
	action_manually_changed = true


func set_by_name(name: String, force_verb: String = "") -> void:
	for i in cursors.size():
		if cursors[i].name == name:
			current_cursor_id = i
			break

	var cycle_pos = CYCLEABLE_VERBS.find(name)
	if cycle_pos >= 0:
		_cycle_index = cycle_pos

	var show_cursor := true
	if ESCProjectSettingsManager.has_setting(SimpleMouseCycleUISettings.SHOW_VERB_CURSOR):
		show_cursor = ESCProjectSettingsManager.get_setting(
			SimpleMouseCycleUISettings.SHOW_VERB_CURSOR
		)

	if show_cursor:
		Input.set_custom_mouse_cursor(
			_resolve_cursor_texture(name),
			Input.CURSOR_ARROW,
			Vector2(32, 32)
		)
	else:
		Input.set_custom_mouse_cursor(null)

	if force_verb.is_empty():
		if name in VISUAL_ONLY_CURSORS:
			pass
		elif name in CYCLEABLE_VERBS:
			escoria.action_manager.set_current_action(name)
		else:
			# Non-cycle cursor states such as exits should pass force_verb.
			escoria.action_manager.set_current_action(cursors[current_cursor_id].name)
	else:
		escoria.action_manager.set_current_action(force_verb)


func set_dialog_choice_cursor() -> void:
	set_by_name(SimpleMouseCycleUISettings.DIALOG_CHOICE_CURSOR_NAME)


func _resolve_cursor_texture(cursor_name: String) -> Texture2D:
	if cursor_name == SimpleMouseCycleUISettings.DIALOG_CHOICE_CURSOR_NAME \
			and ESCProjectSettingsManager.has_setting(SimpleMouseCycleUISettings.DIALOG_CHOICE_CURSOR):
		var override_path = ESCProjectSettingsManager.get_setting(
			SimpleMouseCycleUISettings.DIALOG_CHOICE_CURSOR
		)
		if typeof(override_path) == TYPE_STRING and not override_path.is_empty() \
				and ResourceLoader.exists(override_path):
			var loaded = load(override_path)
			if loaded is Texture2D:
				return loaded

	return cursors[current_cursor_id].texture


func get_last_cycle_verb() -> String:
	return CYCLEABLE_VERBS[_cycle_index]


func set_tool_texture(texture: Texture2D):
	set_process(true)
	$mouse_position/tool.texture = texture


func clear_tool_texture():
	$mouse_position/tool.texture = null
	set_process(false)


func get_current_verb_display_name() -> String:
	var action = escoria.action_manager.current_action
	if action.is_empty():
		return ""
	match action:
		"pickup":
			return "pick up"
		"look":
			return "look at"
		_:
			return action
