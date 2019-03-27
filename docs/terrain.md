# Terrain

Your player and NPCs walk along a defined terrain. You'll need a `NavigationPolygon2D`
for that, and attaching a script for special features like scaling and lighting.

Note that lighting on the terrain is not the same as lighting by `Light2D`, it is modulating
the player and items based on a separate texture. You'll make it white and color in the areas
where you want something to change.

A terrain is not strictly necessary. In rooms like that, all interactions are handled
as if the player had already walked to the target position.

## Scaling

### Scalenodes

The easiest way to make your player and NPCs scale is to use the `terrain_scalenodes.gd`
script. Then you create `Position2D` nodes with `scalenode.gd` attached to them.

The names of these nodes don't matter, except you need `scale_min` and `scale_max`.
Those two should be placed above and below the navpoly.

Anything which is set to scale from the map will linear-interpolate between the `target_scale`
values.

Caveat: although these are `tool` scripts, you can't refresh the scalenode list at the
moment so you will need to refresh the scene when making bigger changes.

### Gradient

The harder, though more versatile way, is to create a separate scalemap texture.

This is further documented in the [Flossmanuals booklight](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/lightening/).

Attach `terrain.gd`.

You'll define a scale range for how much to scale by. The terrain will look for the blue
value of a pixel and scale accordingly. More blue is a bigger scale.

Caveat: for some reason this method is currently very slow, so having many NPCs move
around will probably kill performance.

## Lighting by lightmap

Reading pixels is, for whatever reason, slow. It is necessary for lightmaps, and scalemaps
if you use them. To mitigate the performance problems, there's a script `lightmap_area.gd`
which you would attach to an `Area2D` and draw its polygon or shape around the part of
your lightmap that actually contains information.

## Dynamic navigation

You can attach `nav_poly_instance.gd` to multiple `NavigationPolygonInstance`s, give
them `global_id`s and use `set_active` to toggle where you're allowed to move.

Note that you should use pixel snapping or somesuch to share vertices between the
polygons or they are not considered the same terrain.

