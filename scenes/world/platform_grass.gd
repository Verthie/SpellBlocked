@tool
extends AnimatableBody2D

@onready var platform: Sprite2D = $Platform
@onready var small_platform: Sprite2D = $SmallPlatform

@export_enum("Grass", "Stone", "Clay") var platform_type: int = 0
@export_enum("Bare", "Grass", "Flower", "Mushroom", "Stone") var platform_variant: int = 0
@export_enum("Default", "Small") var platform_size: int = 0

func _ready() -> void:
	_platform_setup()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_platform_setup()

func _platform_setup() -> void:
	platform.frame_coords.x = platform_type
	platform.frame_coords.y = platform_variant
	small_platform.frame_coords.x = platform_type
	small_platform.frame_coords.y = platform_variant
	match platform_size:
		0:
			$CollisionShape2D.scale.x = 1
			platform.show()
			small_platform.hide()
		1:
			$CollisionShape2D.scale.x = 0.635
			platform.hide()
			small_platform.show()
