# Background

The background node acts as a catch-all for input events. Any input event that isn't captured by another interactive element is processed by this node.

To add a background to your scene, add a `Sprite` node as the first child of the `scene` node, name it "background", make sure the `Offset/Centered` property is not checked and add the `globals/background_area.gd` script.

This enables you to use `Area2D` nodes for your items, which lets you draw one or more `CollisionPolygon2D` child nodes to capture input, using only editor tools for the drawing. You can also add `Sprite` nodes as children of the `Area2D` item node if your items are not part of the background image.

### Parallax

To create an illusion of perspective in a 2D game, a technique called parallax scrolling effect can be used. This effect is achieved by adding one or more additional background layers, which are moved at a different speed than the foreground when the camera pans.

To implement a [ParallaxBackground](http://docs.godotengine.org/en/3.0/classes/class_parallaxbackground.html) in Escoria, a `Sprite` with the `globals/background_area.gd` script must be used for the foreground, as described in the previous section. Since the camera limits are calculated from the size of the `Sprite` texture, the image used must cover the visible space of the room, with transparent regions where the parallax layers will be visible.

Each layer must have a `Sprite` child node with the `Offset/Centered` property unchecked, and the parallax image must either be larger than the foreground or be repeated using the `Motion/Mirroring` property of the `ParallaxLayer` node to counter the `Motion/Scale` property, which is used to control how fast the layer scrolls. Remember to adjust the `Transform/Position` property of the `ParallaxLayer` to make sure that the layer covers the left and upper edges of the viewport when the scene is played.

Note: When using `camera_set_zoom` or `camera_set_zoom_height` in combination with parallax backgrounds, the `ParallaxBackground`'s `Scroll/Ignore Camera Zoom` property should be turned off so that the parallax layers do not move when zooming.
