extends Area2D
class_name ParentProjectile

@export var speed: int = 1000
var direction: Vector2 = Vector2.RIGHT

func _ready():
	$SelfDestructTimer.start()

func _physics_process(delta):
	position += direction * speed * delta

func _on_self_destruct_timer_timeout():
	queue_free()

#TODO Wykonać animację niszczenia pocisku
