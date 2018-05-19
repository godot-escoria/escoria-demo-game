# Designing dialogs

The story is usually the cornerstone of an adventure game, and in visual media, stories are often told through interactions between characters. To make it easy to add dialog to your game, Escoria supports a flexible syntax for writing dialogs, backed by a heavily custimizible visual interface. This document is intended to help customize the appearence of such dialogs in your game. For a reference on scripting the dialogs, see the [ESC reference](esc_reference.md).

### Dialog players

To make your dialogs available from esc scripts, they must be added to one of the dialog players. When playing dialogs, the `type` parameter will be used to look up the correct dialog scene by name in the `ResourcePreloader` in either `device/ui/dialog_player.tscn` for the `say` command or `device/ui/dd_player.tscn` for the `?` command. If no `type` parameter is provided or the given type does not exist in the player, the "default" dialog scene will be used.

### Speech dialog

The default speech dialog scene is located in `device/ui/dialog_default.tscn`. If you wish to customize its appearance, make a copy like `device/game/ui/dialog_default.tscn`, and replace the "default" scene in `device/ui/dialog_player.tscn` with your own, using the bottom-pane file picker. Remember that the name in the `ResourcePreloader` refers to the type of dialog UI to use, and that "default" will be used if no `type` parameter is provided.

You may experience difficulties when trying to adjust the `text` node to your liking. Godot isn't very intuitive when it comes to customizing the `RichTextLabel`, but hopefully this will behave more like a simple `Label` in the future. In the meantime, Escoria relies heavily on the current type, as it should, to enable italic and bold font.

The project setting `escoria/platform/dialog_force_centered` will center your dialog text if your game is like SCUMM games, with the dialog above the characters. If you use avatars and big boxes for dialog, you will probably want to leave this disabled.

The dialog players are unlikely to change much upstream, so editing and adding multiple dialog scenes should rarely cause merge conficts. However, if you have multiple game directories within the framework, you are adviced to name your dialog resources sensibly and use the `type` parameter to choose which one to use with the `say` command.

For further reading, see the Floss Manuals section on [speech text](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/dialog-text/).

### Branching dialog

To create unique looking dialog trees, custom made for your game, you can duplicate `device/demo/ui/dd_default.tscn`, and adjust these nodes to your liking:

- `dialog` - This is the root of the branching dialog scene, and you should adjust the `Anchor` and `Margin` properties of it to make dialogs appear where you want within the viewport. As an example, to center position dialog horizontally, you will want to set the left+right anchors to `0.5` (center) and set the left+right margins to minus half the size of your dialog width. This will make sure the dialog is centered, no matter the screen width.
- `bg` - This node can be used as a backdrop for dialog by loading an image into the `Texture` property. You may optionally want to set the `Rect/Size`, `Expand` and  `Visibility/Modulate` properties to use a repeating, semi transparent background.
- `scroll` - This node defines the area of the dialog scene that will be used to display text options. Use the `Rect/Position` and `Rect/Size` properties to set position and size.
- `avatars` - This node defines the area where avatars will be displayed, if set with the optional `type` parameter. To use, add one or more `Sprite`s as children of this node, and use the `Rect/Position` and `Rect/Size` properties to set position and size.
- `item` - This node is the template for text options and is instanced into the dialog tree as needed. Use the `Rect/Min Size/y` property to define the vertical space used to display each line of dialog, and use the exported colors on the `dialog` node to set font color. Once set, you can use the `escoria/platform/dialog_option_height` project setting if you want to quickly change the height of all your dialog tree scenes.

You should not change the size or position of any of the other nodes, since that might make it difficult to make the dialogs appear the way you want.

Additionally, you can tweak the "show" and "hide" animations of the `animation` node however you want. 

For further reading, see the Floss Manuals sections on the [dialog interface](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/how-to-polish-the-game/) and [dialog trees](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/dialog-trees/).

### Font

If you want to change the font of one of your dialogs, use the `Custom Fonts` section on your `Label` or `RichTextLabel`. To use a vector font, select the `New DynamicFont` option from the drop-down, then select `Edit`, and load your font file into the `Font/Font Data` property. If you want to re-use this font in multiple dialogs, you may want to save the font as a resource file (`.tres` file), and use the `Theme` property to load it into your `Label`s and `RichTextLabel`s.
