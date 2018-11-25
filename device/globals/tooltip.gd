extends Label

var force_hide_tooltip = false  # Used by `set_tooltip_visible` to never show

func show():
	assert self.text

	set_tooltip_visible(true)

func hide():
	# Although we try to hide implicit magick, there's no point in having text pending there
	self.text = ""

	set_tooltip_visible(false)

func set_tooltip(text):
	assert typeof(text) == TYPE_STRING

	if force_hide_tooltip:
		# vm.reset_overlapped_obj()
		assert not self.visible
		return

	self.text = text

func set_tooltip_visible(p_visible):
	self.visible = p_visible and self.text and not force_hide_tooltip

func force_tooltip_visible(p_force_hide_tooltip):
	# Not visible (false) means it's hidden
	force_hide_tooltip = not p_force_hide_tooltip
	printt("force-hide tooltip:", force_hide_tooltip)
	if force_hide_tooltip:
		self.hide()
	else:
		self.show()

func set_visible(p_visible):
	visible = p_visible

func _ready():
	vm.register_tooltip(self)

