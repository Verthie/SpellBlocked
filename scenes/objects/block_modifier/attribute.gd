class_name Attribute
extends Node

#signal amount_changed(new_amount)

@export var amount: float = 0: get = get_amount, set = set_amount

func get_amount() -> float:
	return amount

func set_amount(new_amount: float) -> void:
	amount = new_amount
	#amount_changed.emit(new_amount)
