# Exporting your game

When you have finished making your game, you will want to make exports so that others can play it. Escoria currently support GNU/Linux, macOS and Windows, but we will hopefully support the same platforms that Godot does in the future.

### Preparations

The first thing you need to do is to download export templates for the platforms you want to support. Select `Editor > Manage Export Templates` from the menu and click the `Download` button. Select a mirror and wait for the download to finish.

If you want to compile your own export templates, in case you modified the engine in some way, eg. by adding Spine support or cherry-picking commits that haven't hit stable yet, these are the preferred configurations:

  * Linux: `scons platform=x11 tools=no target=release bits=64 builtin_libpng=yes builtin_openssl=yes builtin_zlib=yes debug_symbols=no use_static_cpp=yes use_lto=yes`
  * Windows: `scons platform=windows tools=no`
  * macOS: `scons platform=x11 tools=no`

The Linux variant ensures maximum future-proofness to the extent Godot provides it. Windows is known for good backward compatibility so it doesn't matter. macOS is a bizarre platform to develop for so who knows what the future brings anyway.

Do add `-j` for parallel building with your core count as the value. `use_lto` requires a recent GCC, but this should not present a problem on any modern distribution.

If you use OGG videos for animation sequences, please cherry-pick https://github.com/godotengine/godot/commit/6dc20adadd721bfc31a6b761eb6224975938dbf4 and compile your own export templates. If you don't, the video will be looked for outside the exported `.pck` file and you will have to structure your export manually. It is not fun, especially not when exporting a DMG on macOS. This commit should be in Godot 3.1 when it's released. In the meantime, cherry-picking is the way to go.

### Configuring for export

During development Escoria defaults to having a non-resizable windowed game in FullHD. This is based on the assumption games are not developed for or targeted at lower resolutions. Many setups provide resolutions higher than FullHD and the development experience is much better anyway if previewing the game doesn't occupy all your screen real estate.

When exporting, these preferences must change. It's recommended to set the following conditions in `project.godot`:

  * `window/size/fullscreen=true`
  * `window/size/resizable=true`

This is a hard requirement on macOS and works for everything else as well. The window will not be resized properly for fullscreen unless resizable is also true.

It is further recommended to set the following conditions to avoid showing Escoria's "debug chatter":

  * `run/disable_stdout=true`
  * `run/disable_stderr=true`

### Exporting

When you are ready to make your exports, select `Project > Export` from the menu, and add as many platform presets as you wish. In the `Resources` tab, make sure to add `*.esc` as a filter to export non-resource files, click `Export Project`, choose a path and file name, and click `Save`. Repeat the procedure for the remaining platforms.

You may also want to add files like `*.ogv` if you use OGG videos for animation sequences.

For more details, see the Floss Manuals section on [Exporting projects](http://docs.godotengine.org/en/3.0/getting_started/workflow/export/exporting_projects.html).
