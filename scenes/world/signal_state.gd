extends Node2D

@onready var signal_sprite: Sprite2D = $SignalSprite

func turn_on() -> void:
	signal_sprite.frame = 1

func turn_off() -> void:
	signal_sprite.frame = 0
