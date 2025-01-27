extends StaticBody2D

@export var connectors: Array[LogicElement]
@export_flags_2d_physics() var interactable_entities: int = 5

@export var trigger_enabled: bool = true

var turned_on: bool = false

func _ready() -> void:
	set_trigger(trigger_enabled)

func set_trigger(collision_disabled: bool) -> void:
	$TriggerArea/CollisionShape2D.disabled = !collision_disabled
