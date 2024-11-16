extends Area2D

func _on_body_entered(_body: Node2D) -> void:
	EventBus.changed_interaction_state.emit(true)


func _on_body_exited(_body: Node2D) -> void:
	EventBus.changed_interaction_state.emit(false)
