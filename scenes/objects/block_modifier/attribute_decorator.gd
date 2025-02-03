extends Attribute

var decoratee: Node
var attribute_type: String
var modifier_applied: bool
var current_modifiers: Array

func get_amount() -> float:
	var decorated_amount: float = decoratee.amount

	if modifier_applied:
		# when modifier already applied and current modifier is Ice apply only its friction
		if Globals.current_block_type == "Ice" and attribute_type == "friction":
			decorated_amount = amount
		# when modifier already applied and current modifier is Stone apply only its gravity
		if Globals.current_block_type == "Stone" and attribute_type == "gravity":
			decorated_amount = amount
		if Globals.current_block_type == "Gravity" and attribute_type == "gravity":
			var multiplier_value: float = -1.0 if "Stone" not in current_modifiers else -0.2
			decorated_amount *= multiplier_value
	else:
		decorated_amount = amount

	return decorated_amount
