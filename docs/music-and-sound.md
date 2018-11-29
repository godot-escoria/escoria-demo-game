# Music and Sound

## Music

Make your game come alive with some music.

The background music can be controlled from .esc scripts using the `set_state bg_music` command. To play music when a scene loads, create a new .esc file, load it from the `Events Path`  property of the `scene` node and add the following contents:

```
:ready
set_state bg_music "res://demo/audio/music/demo_melody.ogg"
```

Assuming `demo_melody.ogg` is a music file which exists under that resource path in your project.

### Controlling music streams

Similarly, you can also control music by triggering actions on items in your scene, for instance by using custom `turn_on` and `turn_off` actions on a radio item in your game with the following .esc script added to its `Events Path` property:

```
:turn_on
set_state bg_music "res://demo/audio/music/demo_melody.ogg"

:turn_off
set_state bg_music off
```

### Sound

You play sound files with `play_snd`.

You can add an `AudioStreamPlayer2D` to any item, calling it `audio`. Please see [the reference](esc_reference.md) for more info.

For idle animations, their idle sounds, it's preferred you use the `animation` node to control the audio stream.

## Controlling volume

Currently there exists no API for controlling music through Escoria.

There is a setting `escoria/application/dialog_damp_music_by_db`
which allows you to dampen the background music while someone's
speaking.

See [Decibel scale](http://docs.godotengine.org/en/3.0/tutorials/audio/audio_buses.html) for details.

