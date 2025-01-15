extends StaticBody2D

@export var connectors: Array[LogicElement]
@export_flags_2d_physics() var interactable_entities: int = 5

var turned_on: bool = false
