# Custom signals

(Formerly known as `Right-mouse-button behavior`)

Escoria provides sane defaults for the right mouse button.

Right-clicking on an inventory item looks at it.

You can also configure `escoria/ui/right_mouse_button_action_menu`
and follow the instructions in the [HUD](hud.md) document. You get an action menu that
opens on a right-click.

What if you want more out of the button? Say you want to highlight items or disable the
`"Use Ratchet with Cow"` action.

## Node structure

`game` must still be the lowermost node in your scene tree. However, it may have a child
of type `Node`.

This child is named `signal_script` because it only hosts the script where you implement your
behavior. You do not want to attempt scripting signals without a `Node` to bind to;
see the [connect()](http://docs.godotengine.org/en/latest/classes/class_object.html?highlight=connect#class-object-connect)
documentation. The `target` can not be `self` in a static script and things get real messy
if you try to `preload()` something.

## Scripting

You may name your script however you want, like `ui/rmb_hints.gd` or `ui/rmb_hide_tool.gd`.

It requires only the `_ready():` function, becase it will be the last added to the
scene tree when loading. This means all the nodes and groups will be automagically
available for your convenience.

Attach this script to `$"game/signal_script"`.

Note that you do not have to attach it to the main `game` scene itself, if you're using
a custom one. This is because you may want to have mini-games with different behavior.
However, it is possible to attach it to your main `game` as well.

## Examples

You have an example in `device/demo/ui/rmb_hints.gd`.

Another could look like this:

```
# Create a file like this in your game to define right-mouse-button
# behavior.

extends Node

func hide_current_tool():
	var game = get_parent()

	if game.current_action == "use" and game.current_tool:
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clear_action")
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", "")

func _ready():
	for bg in get_tree().get_nodes_in_group("background"):
		bg.connect("right_click_on_bg", self, "hide_current_tool")

```

