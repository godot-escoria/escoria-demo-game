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

in your game directory and configure `escoria/application/speech_locales_path` to point to it.

This is the list of accepted and supported locales in your game.

The game will crash if you define a locale that's not accepted, so don't add unsupported
locales to your game code or define an unsupported default ;)
