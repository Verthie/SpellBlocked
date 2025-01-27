extends ParentLevel

@onready var animation_player: AnimationPlayer = $LevelElements/Platforms/PlatformGrass2/AnimationPlayer

var platform_moving: bool = false

func _on_platform_animate_body_entered(_body: Node2D) -> void:
	if !platform_moving:
		platform_moving = true
		$LevelElements/Mechanisms/SignalState.turn_on()
		await get_tree().create_timer(0.5).timeout
		$LevelElements/Mechanisms/SignalState.turn_off()
		animation_player.play('platform_move')
		await animation_player.animation_finished
		animation_player.play('platform_move', -1, -1, true)
		await animation_player.animation_finished
		platform_moving = false

func _on_enable_button_trigger_body_entered(body: Node2D) -> void:
	$LevelElements/Mechanisms/PressureButton.call_deferred('remove_collision_exception_with', body)
	$LevelElements/Mechanisms/PressureButton.call_deferred('set_trigger', true)

func _on_disable_button_trigger_2_body_entered(body: Node2D) -> void:
	$LevelElements/Mechanisms/PressureButton.call_deferred('add_collision_exception_with', body)
	$LevelElements/Mechanisms/PressureButton.call_deferred('set_trigger', false)
