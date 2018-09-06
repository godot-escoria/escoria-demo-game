# Starting a game

Escoria looks for a start script for your game.

You can configure its path in `platform/game_start_script`.

It should look like this

```
:start
    change_scene res://game-dir/rooms/your-first-room/scene.tscn
```

Note that the `:start` event is not used anywhere else. The start script
does not use `:load`, because loading save games has to disable events. So
if `:load` was used, your legitimate events at the start of your game would
not work. And not checking for game loads would completely break your game
every time you load a save!

