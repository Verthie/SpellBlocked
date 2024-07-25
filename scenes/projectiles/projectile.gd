extends Area2D
class_name ParentProjectile

@export var speed: int = 1000
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta):
	position += direction * speed * delta
