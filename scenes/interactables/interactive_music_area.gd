extends Area2D

@export var clip_index: int = 0
@export var one_time_trigger: bool = true

func _on_body_entered(_body: Node2D) -> void:
	BgmManager.set_interactive_audioclip(clip_index)
	if one_time_trigger:
		queue_free()
