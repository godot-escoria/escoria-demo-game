# Resource holding game settings.
extends Resource
class_name ESCSaveSettings

# Version of ESCORIA Framework
export var escoria_version: String

# Language of displayed text
export var text_lang: String = ProjectSettings.get_setting("escoria/main/text_lang")

# Language of voice speech
export var voice_lang: String = ProjectSettings.get_setting("escoria/main/voice_lang")

# Whether speech is enabled
export var speech_enabled: bool = ProjectSettings.get_setting(
	"escoria/sound/speech_enabled")

# Master volume (mix of music, voice and sfx)
export var master_volume: float = ProjectSettings.get_setting(
	"escoria/sound/master_volume")

# Volume of music only
export var music_volume: float = ProjectSettings.get_setting(
	"escoria/sound/music_volume")

# Volume of SFX only
export var sfx_volume: float = ProjectSettings.get_setting("escoria/sound/sfx_volume")

# Voice volume only
export var voice_volume: float = ProjectSettings.get_setting(
	"escoria/sound/speech_volume")

# True if game has to be fullscreen
export var fullscreen: bool = false

# True if skipping dialogs is allowed
export var skip_dialog: bool = true
