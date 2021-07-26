# Escoria Rewrite

Libre framework for the creation of point-and-click adventure games with the MIT-licensed multi-platform game engine [Godot Engine](https://godotengine.org).

It is designed so that you can claim it for yourself and modify it to match the needs of your specific game and team.

This repository is big rewrite of the original [Escoria framework](https://github.com/godotengine/escoria/tree/master). Its purpose is to make Escoria work as a plugin for the Godot Engine editor, instead of being a collection of scripts and scenes. It is intended to be easier to use and easier to maintain. 

If you're encountering issues or incompatibilities, please raise an issue on [Escoria's Github repository](https://github.com/godotengine/escoria/issues).

## History

This framework was initially developed for the adventure game
[The Interactive Adventures of Dog Mendonça and Pizzaboy®](http://store.steampowered.com/app/330420)
and later streamlined for broader usages and open sourced as promised to the backers of the Dog Mendonça Kickstarter campaign.

Because of maintainability issues and to make the framework easier for new developers and bring it closer to Godot's standards, the framework was completely rewritten and optimized.

## Authors

In alphabetical order:

* ArturM
* Sylvain Beucler - beuc
* Fleskevor
* Ariel Manzur - punto (original author)
* Julian Murgia - @StraToN
* Dennis Ploeger - @dploeger
* Markus Törnqvist - mjtorn

## Documentation

* [Getting started](docs/getting_started.md)
* [Architecture](docs/architecture.md)
* [Configuration](docs/configuration.md)
* [ESC language documentation](api/esc.md)
* [API reference](docs/api)

## Roadmap

Escoria's development is organized using Github [issues](https://github.com/godotengine/escoria/issues). Take a look, what's planned for the next version.

## Licensing

This framework (scripts, scenes) is distributed under the [MIT license](LICENCE).

### Art credits

#### Logo

Escoria Logo created by Livio Fania (https://liviofania.com/)
Licence: CC-BY

#### Characters

- Mark spritesheet by Marco Giorgini - marcogiorgini.com 
  Licence : CC0 Licence
  https://opengameart.org/content/mark-2d-adventure-game-sprite
  with some additions (talk animations) by Julian Murgia
- Worker spritesheet based on Mark spritesheet by Marco Giorgini - marcogiorgini.com 
  Licence: CC0 Licence
  edited by Julian Murgia

#### Items

* Generic items by Kenney
  Licence: CC0 Licence
  https://www.kenney.nl/assets/generic-items

### Sound credits

* Concrete footstep
  Licence: CC0 Licence
  https://www.kenney.nl/
* “Game Menu Looping” (Licence CC-BY 4.0)
* “Mystical Ocean Puzzle Game” (Licence CC-BY 4.0)
  by Eric Matyas
  www.soundimage.org

### Font

These fonts are provided as an example. Please mind checking the licence before redistributing with your game.

- Caslon Antique 
  https://www.1001fonts.com/caslon-antique-font.html#license
  Licence: Free for personal use - Free for commercial use
  This is the font used in LucasArt's game Curse of Monkey Island.

- Onesize
  https://www.whatfontis.com/Onesize.font
  Licence: Free for personal use
  This is the font used in LucasArt's games The Secret of Monkey Island and Monkey Island 2: Lechuck's Revenge.

## Development

Requirements:

* git
* Current Godot version
* Docker (for updating the API docs)
* Python (>=3) (for updating the ESC reference)

After pushing something to the repository, the API docs will be updated. If you want to update them during
development, run the following from the game directory:

```
rm -rf docs/api
docker run --rm -v $(pwd):/game -v $(pwd)/docs/api:/export gdquest/gdscript-docs-maker:1 /game -o /export -d addons/escoria-core
```

If you changed ESC commands, update the command reference by running 

```
python3 extractesc.py
```

