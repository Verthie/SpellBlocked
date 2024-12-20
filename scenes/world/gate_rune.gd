class_name LogicGate
extends LogicElement

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func gate_open() -> void:
	animation_player.play("open")

func gate_close() -> void:
	animation_player.play_backwards("open")
