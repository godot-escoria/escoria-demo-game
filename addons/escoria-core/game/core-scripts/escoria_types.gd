extends Node

const OBJ_DEFAULT_STATE = "default"

enum EVENT_LEVEL_STATE {
	RETURN, # 0
	YIELD,	# 1
	BREAK,	# 2
	REPEAT,	# 3
	CALL,	# 4
	JUMP	# 5
}
