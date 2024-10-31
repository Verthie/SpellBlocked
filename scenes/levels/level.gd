extends Node2D
class_name ParentLevel

var projectile_direction: Vector2

func _ready():
	Globals.object_amounts = [0,0,0,0]

func _process(_delta):
	if Input.is_action_just_pressed('quit'):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()

func _on_player_shoot(pos: Vector2, scene: PackedScene, create: bool, direction: Vector2):
	var projectile = scene.instantiate() as Area2D
	projectile.position = pos
	projectile.rotation_degrees = rad_to_deg(direction.angle())
	projectile.direction = direction
	projectile_direction = direction
	if create: projectile.create.connect(_on_projectile_body_entered)
	$Projectiles.add_child(projectile)

func _on_projectile_body_entered(pos: Vector2, scene: PackedScene):
	var new_object: RigidBody2D = scene.instantiate() as RigidBody2D
	#new_object.position = pos
	new_object.position = pos + (projectile_direction * -9)
	$Objects.call_deferred("add_child", new_object)
