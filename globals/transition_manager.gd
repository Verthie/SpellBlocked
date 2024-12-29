extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum TransitionType{
	NONE,
	DISSOLVE,
}

func play_transition(type: TransitionType, backwards: bool = false, speed: float = 1.0) -> void:
	var transition_name: String = str(TransitionType.keys()[type]).to_lower()

	if transition_name in animation_player.get_animation_list():
		if !backwards:
			animation_player.play(transition_name, -1, speed)
			await animation_player.animation_finished
		else:
			animation_player.play(transition_name, -1, -speed, true)
			await animation_player.animation_finished
	else:
		push_error("Transition Manager failed to find this type ", type)
