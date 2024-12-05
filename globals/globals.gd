extends Node

var current_block_type: String = "None"
	#set(value):
		#current_block_type = value

var in_modify_state: bool = false

func _process(_delta: float) -> void:
	if current_block_type == "None": #or current_block_type == "Enlarge":
		in_modify_state = false
	else:
		in_modify_state = true

var current_cursor_type: String = "Block"

#var object_amounts: Array = [0,0,0,0]
