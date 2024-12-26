extends Camera2D

@export var target: Player
@export var align_time: float = 1
@export var screen_size: Vector2 = Vector2(320, 190)

func _physics_process(_delta: float) -> void:
	#if not is_instance_valid(Target):
		#var targets: Array = get_tree().get_nodes_in_group("Player")
		#if targets: Target = targets[0]
	#if not is_instance_valid(Target):
		#return

	# Actual movement
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "global_position", desired_position(), align_time)

func desired_position() -> Vector2:
	#print("Player global position: ", Target.global_position, " Camera position: ", (Target.global_position / screen_size).floor() * screen_size + screen_size/2)
	return (target.global_position / screen_size).floor() * screen_size + screen_size/2
