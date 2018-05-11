# Tool scripts

Tool scripts are command line GDScript files which are not exported with the game, but rather serves a purpose during development. These scripts are located in the `tools/` directory, and can be run by invoking Godot from the command line with the option `-s` /`--script` and a valid path to the script. If Godot is in your `$PATH`, the `lockit.gd` script may be run by issuing the following command from the `device/` directory:

    `godot -s ../tools/lockit.gd`

### Internationalization

The `lockit.gd` script is made to help with translation of the game by making sure all strings used in dialogue has a translation ID, which can be used with Godot's `TranslationServer`. When run, the script creates .esc.lockit files for every .esc file in your project, with translation IDs prefixed within each file. Additionally, a .csv file is generated, which carries some information about the context of each string, as well as any conflicting translation IDs found. This .csv file can also be used to create a .csv file which can be loaded into the game from the project settings, as described in the Floss Manuals section on [Internationalization](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/i18n/).
