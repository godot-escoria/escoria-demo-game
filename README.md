# Escoria Rewrite

Libre framework for the creation of point-and-click adventure games with
the MIT-licensed multi-platform game engine [Godot Engine](https://godotengine.org).

It is designed so that you can claim it for yourself and modify it to match
the needs of your specific game and team.

This repository is big rewrite of the original [Escoria framework](https://github.com/godotengine/escoria/tree/master). Its purpose is to make Escoria work as a plugin for the Godot Engine editor, instead of being a collection of scripts and scenes. It is intended to be easier to use and easier to maintain. 

If you're encountering issues or incompatibilities, please raise an issue on [Escoria's Github repository](https://github.com/godotengine/escoria/issues).

## History

This framework was initially developed for the adventure game
[The Interactive Adventures of Dog Mendonça and Pizzaboy®](http://store.steampowered.com/app/330420)
and later streamlined for broader usages and open sourced as promised
to the backers of the Dog Mendonça Kickstarter campaign.

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

* Getting started
* [Architecture](docs/architecture.md)
* [Configuration](docs/configuration.md)
* [ESC language documentation](api/esc.md)

## Roadmap

The rewrite is currently ongoing and certain features of Escoria are missing or require optimization:

### Basic features

* [ ] Implement load/save games
* [ ] Implement switching player characters
* [ ] Visualize scaling in editor

### Optimizations

* [ ] Add the currently unfocused inventory item to the `inventory_item_unfocused` signal of `ESCInventoryItem`

* [ ] The `_hover_stack_pop` method in `main_scene` doesn't pop (=remove the last element from the stack) but rather erases the given item from the stack. This may either be a hidden bug or a naming issue

* [ ] The variable `screen_ofs` of main.gd is always set to Vector2(0, 0). Either it's unused or its function has yet to be documented

* [ ] Should we keep defining the animations in a script instead of a real object? Providing a script as a parameter to a function seems weird

* [ ] Fix all TODO and FIXME places in the code

* [ ] Reimplement all missing ESC commands

### Future features

* [ ] Integrated ESC editor
* [ ] Graphical visualizer of room links
* [ ] Optimize character angles and animation helper

## Licensing

This framework (scripts, scenes) is distributed under the [MIT license](LICENCE).

### Art credits


### Sound credits


### Font

## Development

Requirements:

* git
* Current Godot version
* Current master of [GDScript docs maker](https://github.com/GDQuest/gdscript-docs-maker)

During development, run the following to update the class list:

```
cd gdscripts-docs-maker
rm -rf export &>/dev/null
./generate_reference <path to escoria> -d "addons/escoria"
cp export/* <path to escoria>/docs/api
```

