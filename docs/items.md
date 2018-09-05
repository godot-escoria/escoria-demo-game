# Items

Items are objects that have several attributes specifically designed to make the player character interact with them, using actions defined in their attached .esc script. There are a few different ways to design an item in the editor, but an item saved as a separate scene an instanced into the room typically has the following anatomy:

* [item] - a `Node2D` which an `item.gd` script attached and the properties you want to use for this item
    * "area" - a `Control`, typically a `TextureRect`, which can be without texture, or optionally have the `Textures` properties set for finer control of its appearence
    * "iteract_pos" - a `Position2D` which determines the position the player character will walk to before interacting with the item
    * "animation" - an `AnimationPlayer` used to change properties of the item by using the `set_state` .esc command.
    * "_focus_in" - a `Sprite` to show when the item has focus
    * "_focus_out" - a `Sprite` to show when the item does not have focus
    * "_pressed" - a `Sprite` to show when the item is clicked

Often you will find that you don't need to add all of these child nodes.

## Interaction

The `item.gd` script exports the `action` variable. This is the default action for this object. If you wish, you may also configure a global default action in `escoria/platform/default_object_action`. Now you can leave this empty in the editor and have the player always perform this action by default.

It may be that you want these default actions to require double-clicks. This is configured in `escoria/platform/default_object_action_requires_doubleclick`. It applies to both the global and local default actions.

An item-local default action overrides a global default action, as you'd expect.

## Z-index

By default every room in the game is considered to have faux "depth". This is done by setting the z-index based on the y-coordinate.

If you want things to be flat or manually controlled, you can use Godot's z-indexes by unchecking the `Dynamic Z Index` checkbox.
At least for certain inventory configurations, this is something you must do. If your items don't show up on the HUD, uncheck!

The system isn't perfect, so sometimes you may have to use an `AnimationPlayer` to tweak the z-index given by Godot. Likewise
if your item consists of many nodes, they will have different positions, so some of them may need manual tweaking.

## Background items

There are also times when you want to enable the player to interact with items which are not separate scenes, but drawn directly on the background. For such use cases, you will typically use a `TextureRect` to frame the item, with an optional click mask, and no "area" child node.

* [item] - a `TextureRect` with an `item.gd` script attached and the properties you want to use for this item
    * ...

You can also use an `Area2D` for your background item with a `CollisionPolygon2D` child node, which lets you draw the outline of the item directly in the editor.

* [item] - an `Area2D`  with an `item.gd` script attached and the properties you want to use for this item
    * `CollisionPolygon2D` which defines the shape of the item
    * ...

## Parallax items

Items can also be added to a parallax layer, but this comes with a few caveats. First of all, you need to use an item with the shape defined by a `Control` node, since the mouse cursor cannot interact with an `Area2D` through the foreground layer. Secondly, since these items will be visible to the cursor through the foreground, any items meant to be obstructed by foreground elements will need to be masked by a `Control` node. These masks don't need to be items, but can be `TextureRects` with click masks for more fine grained control of their shape. Do take care not to cover any items in the foreground with these masks though, as that will make them impossible to interact with.

Because parallax layers are offset from the background, interacting with them might lead to surprising results. It is therefore recommended that you add `Position2D` node in the foreground layer where you want the player character to stand when interacting with parallax items. This can be achieved by setting the `Interact Position` property on the item and assigning the correct `Position2D` node in the scene.
