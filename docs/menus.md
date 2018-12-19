# Menus

There are two specific types of menus in Escoria. One is the "main menu"
and the other is the "in-game menu".

These are defined in `escoria/ui/in_game_menu` and `escoria/ui/main_menu`.

The menu system is somewhat intricate and certainly not final or stable
at the time of writing this. For example localization is quite lacking
when textures are used for buttons.

## Prior documentation

The documentation [at flossmanuals](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/game-menues/) is fairly well up to date,
so you may use that as a reference as well.

## Required nodes

Your base node must be `Control`.

You are free to use `Container` nodes to lay out your menu.

Attach `ui/menu_button.gd` or `ui/menu_texturebutton.gd` to your menu buttons and `ui/lang_button.gd`
to your language-changing buttons.

The buttons' signal handlers are resolved dynamically. This means that you
should name the buttons like

  * new_game
  * continue
  * exit
  * credits
  * instructions
  * save

The use of `TextureButton` is possible if you don't intend to switch locales.
Sometime in the future we would like to support localized `TextureButton` buttons.

## Optional nodes

If you want background music, add an `AudioStreamPlayer` by the name
of `stream` and set a file in the `bg_sound` variable. It will play
and loop automatically

## Spawning menus

By default a menu is requested by hitting the escape button. You can
configure this in the `Input Map` tab in your project settings.

The menu that opens up is the in-game menu.

The main menu is used only when starting the game.

## Confirm popup

The structure similar to a regular menu. You have a base `Control`.
Then one `Control` named after each locale; create one and call it "en" in doubt.

In these you can have eg. `TextureRect`s called

  * UI_QUIT_CONFIRM
  * UI_NEW_GAME_CONFIRM

Optionally you can use the `ui/translated_label.gd` or `ui/translated_rtlabel.gd`
scripts to pull text from localization.

Which are hidden by default and shown on demand.

You must also have the following

  * yes
  * no

They must be visible, because they are your yes/no buttons.

The types on any of these don't matter, but *their names do*.

If you have multiple locales, hide the top locale-named nodes, all of
them, or the code might pass the click to the wrong button and ignore it.

Any means of passing in messages to the confirmation popups has been
deprecated as not being frameworky enough; that would require altering
Escoria code for a scene that's created by the developer anyway.

## Credits

You may configure a credits screen in `escoria/ui/credits`, and an end
credits screen in `escoria/ui/end_credits`.

This is pretty free-form, but the simplest form is

  * credits (`Control`)
    * background (`TextureRect`)
    * menu (`TextureRect`)

Then you attach the `globals/credits.gd` script to the `credits` node
and everything should work as expected.

You can use the same script for the end credits, but if you want eg.
music there, you have to make a copy and edit that script. Or make
it configurable and submit a pull request with changes and removal
of this statement.

Protip: if you end your game on a fade out, you will not be able to
see the end credits, as `telon` will have made it all black.

You will then make a copy of `credits.gd` for your game, call it
`end_credits.gd` and attach that to `credits`. Then you'll add the
following line to `_ready()`:

```
get_tree().call_group("game", "telon_play_anim", "fade_in")
```

