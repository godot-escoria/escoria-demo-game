tool
extends Button

# Currently erases your setup if you have the player partially / completely configured


var PlayerDirectionCount = 4
const DIRNAMES4 = ["_up", "_right", "_down", "_left"]
const DIRNAMES8 = ["_up", "_up_right", "_right", "_down_right", "_down", "_down_left", "_left", "_up_left"]

func _enter_tree():
	connect("pressed", self, "clicked")


func clicked():
	print("Fixing player animations.")
	var SelectedNode = EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes()
	if SelectedNode.size() == 0:	# No node selected in the editor
		return
#	if not SelectedNode[0] is ESCAnimationResource: # Not an ESCItem. For some reason it's returning an Area2D resource for ESCItems
#		return										# Possibly https://github.com/godotengine/godot-proposals/issues/18
	if not "animations" in SelectedNode[0]:
		print("Selected node does not appear to be an ESCItem.")
		return

	if SelectedNode[0].global_id == null or SelectedNode[0].global_id.length() == 0:
		print("Please give the character a global_id.")
		return

	var PlayerName = SelectedNode[0].global_id

	var Anim = SelectedNode[0].animations	# get_class for animations returns "Resource"
	if Anim == null:	# They haven't set up an ESCAnimationResource
		print("Please create an ESCAnimationResource for the \"Animations\" parameter")
		return

	Anim.dir_angles.clear()
	Anim.directions.clear()
	Anim.idles.clear()
	Anim.speaks.clear()
#

	var ResS
	var Divisor = 360 / PlayerDirectionCount
	var LastAngle = 360 - (Divisor / 2)
	for Loop in range(PlayerDirectionCount):
		var Res = ESCDirectionAngle.new()
		Res.angle_start = LastAngle % 360
		Res.angle_size = Divisor
		Anim.dir_angles.append(Res)
		LastAngle += Divisor

	for Loop in range(PlayerDirectionCount):
		ResS = ESCAnimationName.new()
		if PlayerDirectionCount == 4:
			ResS.animation = PlayerName + DIRNAMES4[Loop]
		elif PlayerDirectionCount == 8:
			ResS.animation = PlayerName + DIRNAMES8[Loop]
		else:
			ResS.animation = PlayerName + "_dir" + str(Loop + 1)
		Anim.directions.append(ResS)
		print(str(ResS))#


	for Loop in range(PlayerDirectionCount):
		var Res = ESCAnimationName.new()
		if PlayerDirectionCount == 4:
			Res.animation = PlayerName + "_idle" + DIRNAMES4[Loop]
		elif PlayerDirectionCount == 8:
			Res.animation = PlayerName + "_idle" + DIRNAMES8[Loop]
		else:
			Res.animation = PlayerName + "_idle_dir" + str(Loop + 1)
		Anim.idles.append(Res)

	for Loop in range(PlayerDirectionCount):
		var Res = ESCAnimationName.new()
		if PlayerDirectionCount == 4:
			Res.animation = PlayerName + "_speaks" + DIRNAMES4[Loop]
		elif PlayerDirectionCount == 8:
			Res.animation = PlayerName + "_speaks" + DIRNAMES8[Loop]
		else:
			Res.animation = PlayerName + "_speaks_dir" + str(Loop + 1)
		Anim.speaks.append(Res)
