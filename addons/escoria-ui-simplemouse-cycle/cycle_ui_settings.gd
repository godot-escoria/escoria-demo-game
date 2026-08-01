extends Resource
class_name SimpleMouseCycleUISettings


const SETTINGS_ROOT = "escoria/ui_simplemouse_cycle"

## When enabled, the mouse cursor icon reflects the current verb.
const SHOW_VERB_CURSOR = "%s/show_verb_cursor" % SETTINGS_ROOT

## When enabled, the tooltip includes the current verb text (e.g. "look Door").
const SHOW_VERB_IN_TOOLTIP = "%s/show_verb_in_tooltip" % SETTINGS_ROOT

## Optional texture used while the player is selecting a dialog answer.
## If empty, the `dialog_choice` cursor from verbs_mouseicons.tscn is used.
const DIALOG_CHOICE_CURSOR = "%s/dialog_choice_cursor" % SETTINGS_ROOT

## Name of the verbs_menu cursor node used for dialog answer selection.
const DIALOG_CHOICE_CURSOR_NAME = "dialog_choice"
