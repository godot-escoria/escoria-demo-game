# Languages, tooltips and dialog text

Or how I learned to stop worrying and love internationalization.

## Language configuration

Escoria supports separate languages for text and voice. Text includes speech and tooltips,
though tooltips are a bit special.

These are configured in your project settings as defaults, but whoever plays your game can
alter them, save them and load them.

### Tooltip

There is a semi-magical configuration `escoria/application/tooltip_lang_default`. It helps
to understand that it's a bit of a misnomer. It's not really a default
language, but the language _you the developer_ used when writing tooltips for
items in the editor.

Its purpose is to see if we can avoid translating tooltips. If the current locale matches
the one you used, we can avoid translating!

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

## Text locales

Translating the texts are documented in [The Escoria book](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/i18n/)

Since the texts are passed through translation, if you don't have a "translation" for your
current language, there will be a notification about it in your dialog text. Hopefully this
will be addressed at a later stage.

