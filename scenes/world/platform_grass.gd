@tool
extends AnimatableBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

#@export_range(0,2,1) var platform_type: int = 0
@export_enum("Grass", "Stone", "Clay") var platform_type: int = 0
@export_enum("Bare", "Grass", "Flower", "Mushroom", "Stone") var platform_variant: int = 0

func _ready() -> void:
	sprite_2d.frame_coords.x = platform_type
	sprite_2d.frame_coords.y = platform_variant

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		sprite_2d.frame_coords.x = platform_type
		sprite_2d.frame_coords.y = platform_variant
