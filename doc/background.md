# Background

The background node acts as a catch-all for input events. Any input event that isn't captured by another interactive element is processed by this node.

To quickly add a background to your scene, add a `TextureRect` node as the first child of the `scene` node, name it "background" and add the `globals/background.gd` script.

The drawback of this method, however, is that adding items to your scene with complex shapes becomes difficult, since you have to use `TextureButton`s with click masks, which have to be made with external drawing tools.

For such use cases, the alternative is to use a `Sprite` for your background, name it "background", make sure the `Offset/Centered` property is not checked and add the `globals/background_area.gd` script.

This enables you to use `Area2D` nodes for your items, which lets you draw one or more `CollisionPolygon2D` child nodes to capture input, using only editor tools for the drawing. You can also add `Sprite` nodes as children of the `Area2D` item node if your items are not part of the background image.
