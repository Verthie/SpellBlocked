extends Area2D

@export var checkpoint_id: int = 1
@export var one_time_trigger: bool = true
@export_flags("Player Position:1", "Music Clip:2", "Block Instances:4", "Level Block Positions:8") var save_parameters: int = 3
#TODO if block instances saved: track block amount, track instance positions, track block types
#TODO level block positions

func _on_body_entered(body: Node2D) -> void:
	if Globals.previous_checkpoint_id != checkpoint_id:
		EventBus.entered_checkpoint.emit(checkpoint_id, save_parameters)
		if one_time_trigger:
			queue_free()
