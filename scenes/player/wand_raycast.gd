extends RayCast2D

signal spell_blocked(cast_blocker: Node)

var raycast_obstruction: bool = false # Zależne od kolizji raycasta
var in_spell_block: bool = false

func _process(_delta: float) -> void:
	handle_sight_obstruction()

func handle_sight_obstruction() -> void:
	look_at(get_global_mouse_position())
	target_position.x = get_local_mouse_position().length()

	if is_colliding() and get_collider() is CastBlocker:
		var cast_blocker: CastBlocker = get_collider()
		spell_blocked.emit(cast_blocker)
		in_spell_block = true
	elif in_spell_block:
		spell_blocked.emit(null)
		in_spell_block = false

	var angle_to_player: float = get_angle_to(owner.position)

	if enabled:
		if (is_colliding() and get_collider() is not CastBlocker) or (owner.is_on_floor() and !owner.can_see_through and (angle_to_player > -3.1 and angle_to_player < -1.6)): #or player_on_edge_check:
			#print("colliding with: ", ray_cast_2d.get_collider())
			raycast_obstruction = true
		else:
			raycast_obstruction = false

		EventBus.obstructed.emit(raycast_obstruction)
