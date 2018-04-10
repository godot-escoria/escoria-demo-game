# Languages, tooltips and dialog text

Or how I learned to stop worrying and love internationalization.

## Language configuration / Text locales

Escoria supports separate languages for text and voice. Text includes speech and tooltips.

These are configured in your project settings as defaults, but whoever plays your game can
alter them, save them and load them, if you provide more than one language option.

### Development language and translations

Set the language code used during development in `escoria/platform/development_lang`. This means the language you use for tooltips and writing dialog.

This is required so Escoria can skip the translation code if the game is
in the same language as during development.

Translating the texts are documented further in [The Escoria book](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/i18n/)

### Text timeout

In case you don't have audio to determine how long your dialog text is visible, you can
change the `escoria/application/text_timeout_seconds` to your liking. This is how quickly
the dialog text disappears on its own.

## Speech locales

You must create a file like

```
var speech_locales = ["en", "de", "fr"]
```

in your game directory and configure `application/speech_locales_path` to point to it.

This is the list of accepted and supported locales in your game.

The game will crash if you define a locale that's not accepted, so don't add unsupported
locales to your game code or define an unsupported default ;)

## Dialog overlay

To keep lag to a minimum when displaying dialog text, the `dialog player` is a `ResourcePreloader`,
which packs the scene that displays your text.

The default is located in `device/ui/dialog_default.tscn`. If you wish to customize its appearance,
make a copy like `device/game/ui/dialog_default.tscn`. Note that the "default" in the name refers
to the type of dialog UI to use. Refer to doc/esc_reference.md for details.

You may experience pain when trying to adjust the `text` node to your liking. Godot isn't very
intuitive when it comes to expanding the `RichTextLabel`. Hopefully this will behave more like a
simple `Label` in the future. In the meantime, Escoria relies heavily on the current type, as it
should to enable italic and bold font.

The setting `escoria/platform/dialog_force_centered` will center your dialog text if your
game is like SCUMM games, with the dialog above the characters. If you use avatars and big boxes
for dialog, you will probably want to leave this disabled.

Last you will need to - sadly - edit the Escoria code itself. `device/ui/dialog_player.tscn` is
the file where this is defined, so you can edit it with the Godot editor, using the bottom-pane
file picker, and update your path to `device/game/ui/dialog_default.tscn`.

This code is very deeply involved down the stack to the game scene itself, so generalizing it in
a framework fashion is non-trivial, but hopefully a cleaner solution will appear.

