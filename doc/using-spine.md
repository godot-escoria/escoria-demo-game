# Using Spine

[Spine](http://esotericsoftware.com/spine-in-depth) is an animation program that is not
officially supported by Godot, but there exists a [spine module](https://github.com/GodotExplorer/spine/)
that can be added to the `modules/` directory in your Godot source tree and built
with eg. `schedtool -D -e ccache scons platform=x11 tools=yes target=release_debug`
or whatever you like.

## Caveats

NOTE: Some of Escoria's requirements have not been merged to GodotExplorer's repository, so
until further notice, use [mjtorn's fork](https://github.com/mjtorn/spine/) instead.

Do note that Spine animations cannot be played in reverse by design. Trying to do
so will issue an error.

The code is generally experimental, though player animations seem to work fine.

## Using Spine scenes

A `Spine` scene is basically a combination of `AnimatedSprite` and `AnimationPlayer`.

We will now assume you want your player character to be animated using a `Spine` node in the
tree instead of the usual sprites and animations. No other types, like items, are currently supported,
but will probably be in the near future.

Call your `Spine` node by the name `animation`.

Simple as that! The Escoria code has a lot of effort in it to be completely transparent in
ESC scripts, so do report errors.

