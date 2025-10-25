## Resource holding game settings. Note that we call directly to ProjectSettings
## for instance variable initialization since this class is instantiated from
## escoria.gd.
extends Resource
class_name ESCSaveSettings

## Version of ESCORIA Framework.
@export var escoria_version: String

## Language of displayed text.
@export var text_lang: String = ProjectSettings.get_setting(
	"escoria/main/text_lang"
)

## Language of voice speech.
@export var voice_lang: String = ProjectSettings.get_setting(
	"escoria/main/voice_lang"
)

## Whether speech is enabled.
@export var speech_enabled: bool = ProjectSettings.get_setting(
	"escoria/sound/speech_enabled")

## Master volume (mix of music, voice and sfx).
@export var master_volume: float = ProjectSettings.get_setting(
	"escoria/sound/master_volume")

## Volume of music only.
@export var music_volume: float = ProjectSettings.get_setting(
	"escoria/sound/music_volume")

## Volume of SFX only.
@export var sfx_volume: float = ProjectSettings.get_setting(
	"escoria/sound/sfx_volume"
)

## Speech volume only.
@export var speech_volume: float = ProjectSettings.get_setting(
	"escoria/sound/speech_volume")
	
## Ambient volume only.
@export var ambient_volume: float = ProjectSettings.get_setting(
	"escoria/sound/ambient_volume")

## True if game has to be fullscreen.
@export var fullscreen: bool = ProjectSettings.get_setting(
	"display/window/size/mode") == DisplayServer.WINDOW_MODE_FULLSCREEN

## Dictionary containing all user-defined settings.
@export var custom_settings: Dictionary
