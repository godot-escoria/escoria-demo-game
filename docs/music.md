# Music

Make your game come alive with some music.

The background music can be controlled from .esc scripts using the `set_state bg_music` command. To play music when a scene loads, create a new .esc file, load it from the `Events Path`  property of the `scene` node and add the following contents:

```
:ready
set_state bg_music "res://demo/audio/music/demo_melody.ogg"
```

Assuming `demo_melody.ogg` is a music file which exists under that resource path in your project.

Similarly, you can also control music by triggering actions on items in your scene, for instance by using custom `turn_on` and `turn_off` actions on a radio item in your game with the following .esc script added to its `Events Path` property:

```
:turn_on
set_state bg_music "res://demo/audio/music/demo_melody.ogg"

:turn_off
set_state bg_music off
```

