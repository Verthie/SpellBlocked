extends Node

signal ui_update(type: int, amount: int)
signal ui_current(previous_type: int, current_type: int)

var object_amounts = [0,0,0,0]

var current_object_type: int = 0:
	set(value):
		var previous_type: int = current_object_type
		current_object_type = value
		ui_current.emit(previous_type, current_object_type)

var current_object_amount_create: int = 0:
	set(value):
		object_amounts[current_object_type] += value
		current_object_amount_create = 0
		ui_update.emit(current_object_type, object_amounts[current_object_type])

var object_type_destroy: int = 0:
	set(value):
		object_amounts[value] += 1
		#print(object_amounts)
		#print("Sent to function:", value, " ", object_amounts[value])
		ui_update.emit(value, object_amounts[value])
