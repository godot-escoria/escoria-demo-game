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

There is a minimum subset of things that must be supported in the
menus. They are looked for by their `name`, so you must have the
following defined.

  * new_game
  * continue
  * exit

Optionally you may also have

  * save
  * settings
  * credits

(This list should be expanded to include loading a saved game in
case your game has multiple save slots.)

The use of `TextureRect` is recommended.

## Spawning menus

By default a menu is requested by hitting the escape button. You can
configure this in the `Input Map` tab in your project settings.

The menu that opens up is the in-game menu.

The main menu is used only when starting the game.

## Confirm popup

The structure similar to a regular menu. You have a base `Control`.

In this you can have `TextureRect`s called

  * UI_QUIT_CONFIRM
  * UI_NEW_GAME_CONFIRM

Which are hidden by default and shown on demand.

This is maybe the least final part of the code. For example hitting
`new_game` will start a new popup menu with `UI_NEW_GAME_CONFIRM`, but
the confirm_popup.gd script supports having a message passed in and
set into a `Label` named `message`.

You can create a functioning game using the above description, but
there is still work to do in supporting everything you may ever want.

