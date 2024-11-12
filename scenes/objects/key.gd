extends Area2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var rand_shine_timer: Timer = $RandShineTimer

func _process(_delta: float) -> void:
	if rand_shine_timer.is_stopped():
		rand_shine_timer.start()


func _on_rand_shine_timer_timeout() -> void:
	animation_tree.set("parameters/TimeSeek/seek_request", 0.0)
	animation_tree.set("parameters/add_shine/add_amount", 1.0)
