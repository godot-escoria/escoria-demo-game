# HUD

The HUD layer contains the tooltip, the verb or action menu and the inventory.

By default Escoria is configured to use an "old-school SCUMM" layout, with a verb
menu to the bottom-left side and the inventory to the bottom-right.

An alternative HUD is provided as well, `ui/hud_minimal.tscn`.

This documentation exists because of some limitations in how Godot's scenes work.

Caveat: verb and action menus are incompatible. You will experience problems if you
use a verb menu and configure an action menu in your settings. You have been warned!

## Customizing the verb menu

First you'll have to make a copy of `device/globals/game.tscn` to `game/game.tscn`
so you can replace the placeholder HUD. Remember that the HUD contains the verb menu.

Then you create a verb menu to your liking. You may copy `device/demo/ui/verb_menu.tscn`
to `game/ui/verb_menu.tscn` and use it as your base. Hook this up in `game/game.tscn`

Use your `game/game.tscn` as your bottom-most node in the scene tree.

Last you'll have to copy `device/ui/hud.tscn` to `game/ui/hud.tscn`. Alter it to
use your new verb menu.

Adapting the steps above, you may also replace the inventory in your HUD.

You can configure which HUD to use in the project settings. The path is
`Escoria -> Ui -> Hud`.

If you want something completely unique to your needs, you may create a completely
new HUD scene in your `game/ui/` directory and configure the settings accordingly.
This is in case you don't want an inventory at all or want something new in your
HUD.

From there on you may also create a unique-to-your-needs copy of the `hud.gd`
script and use it in your HUD scene.

## Making games with an action menu

By action menu we mean a "new-school SCUMM" menu, also known as a "verb coin".

Since Escoria uses the "old-school SCUMM" UI layout, with a verb menu, it is
visible as a placeholder even when you don't want it. Let's address that.

The first step is to add `game_am.tscn` instead of `game.tscn` as your lowermost
node in the scene tree. This does not contain the verb-menu placeholder.

Second you'll want to configure `Escoria -> Ui -> Hud` use `res://ui/hud_minimal.tscn`.

Your action menu is a scene like any other. Create it as `device/game/ui/action_menu.tscn`
and configure it into `Escoria -> Ui -> Action Menu`.

The inventory is also a scene. You may take example from `device/demo/ui/inventory.tscn`
and place it in `device/game/ui/inventory.tscn`. Configure it in `Escoria -> Ui -> Inventory`.

