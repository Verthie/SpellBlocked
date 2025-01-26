extends ParentLevel


func _on_platform_animate_body_entered(_body: Node2D) -> void:
	$LevelElements/Mechanisms/SignalState.turn_on()
	await get_tree().create_timer(0.5).timeout
	$LevelElements/Mechanisms/SignalState.turn_off()
	# play platform animation
	# await animation_player.animation_finished
