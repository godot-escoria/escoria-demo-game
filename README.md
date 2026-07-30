# Escoria Demo Game

![](https://raw.githubusercontent.com/godot-escoria/.github/main/design/escoria-logo-small.png)

[![Join our Discord](https://img.shields.io/discord/884336424780984330.svg?label=Join%20our%20Discord&logo=Discord&colorB=7289da&style=for-the-badge)](https://discord.com/invite/jMxJjuBY5Z)

Libre framework for the creation of point-and-click adventure games with the multi-platform game engine [Godot Engine](https://godotengine.org).

Check out the [Escoria documentation](https://docs.escoria-framework.org), especially the Getting Started Guide for further details.

If you want to contribute to the development of Escoria, please read our [Contribution guidelines](https://github.com/godot-escoria/.github/blob/main/CONTRIBUTING.md).

This is the demo game that acts as a testing ground for future Escoria development and a general showcase of its features.

## Godot Engine versions to be used

Escoria is meant to work with both Godot Engine 4.6.x and 4.7.x. However, some API changes between 4.6 and 4.7 that Escoria uses forces some tweaks in
a script: 

	- res://addons/escoria-core/game/core-scripts/esc_item.gd

Escoria will detect on launch if this script needs to be replaced with the according one for your version of Godot Engine.

However, if you have made some changes in these files for your own build of Escoria, you may want to apply the necessary changes yourself.
To do so, in `esc_item.gd`, the `_get_configuration_warnings()` method needs to return:

	- 4.6: `return "\n".join(_scene_warnings)`
	- 4.7: `return _scene_warnings`

## Art credits

### Characters

- Mark spritesheet by Marco Giorgini - marcogiorgini.com 
  Licence : CC0 Licence
  https://opengameart.org/content/mark-2d-adventure-game-sprite
  with some additions (talk animations) by Julian Murgia
- Worker spritesheet based on Mark spritesheet by Marco Giorgini - marcogiorgini.com 
  Licence: CC0 Licence
  edited by Julian Murgia

### Items

* Generic items by Kenney
* Animal pack redux by Kenney
  Licence: CC0 Licence
  https://www.kenney.nl/assets/generic-items

## Sound credits

* Concrete footstep
  Licence: CC0 Licence
  https://www.kenney.nl/
* “Game Menu Looping” (Licence CC-BY 4.0)
* “Mystical Ocean Puzzle Game” (Licence CC-BY 4.0)
  by Eric Matyas
  www.soundimage.org
* "Ambient bird sounds"
  License: CC0
  [https://freesound.org/people/Garuda1982/sounds/691629/](https://freesound.org/people/Garuda1982/sounds/691629/)

## Cursors

* Pointers part 4 by "yd"
  Licence: CC0 Licence
  https://opengameart.org/content/pointers-part-4x
  edited by Julian Murgia

## Font

These fonts are provided as an example. Please mind checking the licence before redistributing with your game.

- Caslon Antique 
  https://www.1001fonts.com/caslon-antique-font.html#license
  Licence: Free for personal use - Free for commercial use
  This is the font used in LucasArt's game Curse of Monkey Island.

- Onesize
  https://www.whatfontis.com/Onesize.font
  Licence: Free for personal use
  This is the font used in LucasArt's games The Secret of Monkey Island and Monkey Island 2: Lechuck's Revenge.
