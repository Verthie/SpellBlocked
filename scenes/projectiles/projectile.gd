extends Area2D
class_name ParentProjectile

@onready var self_destruct_timer: Timer = $SelfDestructTimer

@export var speed: int = 1000
var direction: Vector2 = Vector2.RIGHT

func _ready():
	self_destruct_timer.start()

func _physics_process(delta):
	position += direction * speed * delta

func _on_self_destruct_timer_timeout():
	queue_free()

#TODO Wykonać animację tworzenia i niszczenia pocisku
