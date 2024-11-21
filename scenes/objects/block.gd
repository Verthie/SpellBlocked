extends RigidBody2D

#var can_modify: bool = false

func destroy() -> void:
	#if can_modify:
	queue_free()
