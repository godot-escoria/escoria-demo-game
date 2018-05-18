# Exporting your game

When you have finished making your game, you will want to make exports so that others can play it. Escoria currently support GNU/Linux, macOS and Windows, but we will hopefully support the same platforms that Godot does in the future.

### Preparations

The first thing you need to do is to download export templates for the platforms you want to support. Select `Editor > Manage Export Templates` from the menu and click the `Download` button. Select a mirror and wait for the download to finish.

### Exporting

When you are ready to make your exports, select `Project > Export` from the menu, and add as many platform presets as you wish. In the `Resources` tab, make sure to add `*.esc` as a filter to export non-resource files, click `Export Project`, choose a path and file name, and click `Save`. Repeat the procedure for the remaining platforms.


For more details, see the Floss Manuals section on [Exporting projects](http://docs.godotengine.org/en/3.0/getting_started/workflow/export/exporting_projects.html).
