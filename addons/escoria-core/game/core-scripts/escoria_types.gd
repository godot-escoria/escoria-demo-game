extends Node

const OBJ_DEFAULT_STATE = "default"

## Custom nodes:
#var ESCBackground = preload("res://addons/escoria-core/game/core-scripts/escbackground.gd")
#var ESCCharacter = preload("res://addons/escoria-core/game/core-scripts/esccharacter.gd")
#var ESCItem	= preload("res://addons/escoria-core/game/core-scripts/escitem.gd")
#var ESCItemsInventory = preload("res://addons/escoria-core/game/core-scripts/items_inventory.gd")
#var ESCInventoryItem = preload("res://addons/escoria-core/game/core-scripts/inventory_item.gd")
#var ESCPlayer = preload("res://addons/escoria-core/game/core-scripts/escplayer.gd")
#var ESCRoom = preload("res://addons/escoria-core/game/core-scripts/escroom.gd")
#var ESCTerrain = preload("res://addons/escoria-core/game/core-scripts/escterrain.gd")
#var ESCTriggerZone = preload("res://addons/escoria-core/game/core-scripts/esctriggerzone.gd")

enum EVENT_LEVEL_STATE {
	RETURN, # 0
	YIELD,	# 1
	BREAK,	# 2
	REPEAT,	# 3
	CALL,	# 4
	JUMP	# 5
}


"""
ESCState is a helper class used to read ESC files. Once the ESC file is read and
decoded into ESCEvents and ESCCommands, the ESCState instance is removed.
"""
class ESCState:
	var file # File or Dictionary
	var line # String, can be null
	var indent : int
	var line_count : int
	
	func _init(p_file, p_line, p_indent, p_line_count):
		file = p_file
		line = p_line
		indent = p_indent
		line_count = p_line_count
	
	func _to_string():
		return """ESCState: {
			file: """ + file + """,
			line: """ + line + """,
			indent: """ + indent + """,
			line_count: """ + line_count + """
		}"""


class ESCEvent:
	var ev_name : String
	var ev_level : Array
	var ev_flags : Array

	func _init(p_name, p_level, p_flags):
		ev_name = p_name
		ev_level = p_level
		ev_flags = p_flags
	
	func _to_string():
		return """ESCEvent: {
			ev_name: """ + ev_name + """,
			ev_level: """ + String(ev_level) + """,
			ev_flags: """ + String(ev_flags) + """
		}"""


class ESCCommand:
	var name : String
	var params : Array
	var conditions : Dictionary
	var flags : Array
	
	func _init(p_name):
		name = p_name
		params = []

	func _to_string():
		return """ESCCommand: {
			name: """ + name + """,
			params: """ + String(params) + """,
			conditions: """ + String(conditions) + """,
			flags: """ + String(flags) + """
		}"""
