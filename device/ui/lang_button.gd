extends BaseButton

# Emits a signal for the given language. Name the buttons after the locale!

func pressed():
	emit_signal("language_selected", self.name)

func _ready():
	add_user_signal("language_selected", ["lang"])

