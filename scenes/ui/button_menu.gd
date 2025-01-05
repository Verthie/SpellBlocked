class_name ButtonMenu
extends Button

@export var scene_to_switch: PackedScene
@export var threaded: bool
@export var transition: TransitionManager.ShaderTransitionType = TransitionManager.ShaderTransitionType.NONE
@export_range(0.1, 4, 0.1) var transition_speed: float = 1.0
