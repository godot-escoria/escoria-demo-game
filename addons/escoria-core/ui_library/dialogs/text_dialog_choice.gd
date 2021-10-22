extends ESCDialogOptionsChooser

export(Color, RGB) var color_normal = Color(1.0,1.0,1.0,1.0)
export(Color, RGB) var color_hover = Color(165.0,42.0,42.0, 1.0)
export(Font) var font


func _ready() -> void:
	hide_chooser()
	

func _process(delta: float) -> void:
	if $MarginContainer.visible and self.dialog and self.dialog.timeout > 0:
		$TimerProgress.value = (
			self.dialog.timeout - $Timer.time_left
		) / self.dialog.timeout * 100


func show_chooser():
	var _vbox = $MarginContainer/ScrollContainer/VBoxContainer
	for option_node in _vbox.get_children():
		_vbox.remove_child(option_node)
	
	_remove_avatar()
	
	for option in self.dialog.options:
		var _option_node = Button.new()
		_option_node.text = (option as ESCDialogOption).option
		_option_node.flat = true
		_option_node.add_color_override("font_color", color_normal)
		_option_node.add_color_override("font_color_hover", color_hover)
		_option_node.add_font_override("font", font)
		_vbox.add_child(_option_node)
		_option_node.connect("pressed", self, "_on_answer_selected", [option])
	
	if self.dialog.avatar != "-":
		$AvatarContainer.add_child(
			ResourceLoader.load(self.dialog.avatar).instance()
		)
	
	$MarginContainer.show()
	
	if self.dialog.timeout > 0:
		$Timer.start(self.dialog.timeout)


func hide_chooser():
	$MarginContainer.hide()
	

func _option_chosen(option: ESCDialogOption):
	_remove_avatar()
	$TimerProgress.value = 0
	emit_signal("option_chosen", option)


func _on_answer_selected(option: ESCDialogOption):
	_option_chosen(option)


func _on_Timer_timeout() -> void:
	_option_chosen(self.dialog.options[self.dialog.timeout_option - 1])


func _remove_avatar():
	if $AvatarContainer.get_child_count() > 0:
		$AvatarContainer.remove_child($AvatarContainer.get_child(0))
