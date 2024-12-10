extends Node

signal friction_changed(new_friction: float)
signal gravity_changed(new_gravity: float)

@onready var friction: Attribute = $Friction:
	set(new_friction):
		friction = new_friction
		friction_changed.emit(friction.amount)

@onready var gravity: Attribute = $Gravity:
	set(new_gravity):
		gravity = new_gravity
		gravity_changed.emit(gravity.amount)

var original_values: Array[float]

func _ready() -> void:
	friction_changed.emit(friction.amount)
	gravity_changed.emit(gravity.amount)
	original_values = [friction.amount, gravity.amount]
