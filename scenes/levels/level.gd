extends Node2D
class_name ParentLevel

func _on_player_shoot(pos: Vector2, type: PackedScene, create: bool, direction: Vector2):
	var projectile = type.instantiate() as Area2D
	projectile.position = pos
	projectile.rotation_degrees = rad_to_deg(direction.angle())
	projectile.direction = direction
	if create: projectile.create.connect(_on_projectile_body_entered)
	$Projectiles.add_child(projectile)

func _on_projectile_body_entered(pos: Vector2, type: PackedScene):
	print(pos, type)
	var new_object = type.instantiate() as RigidBody2D
	new_object.position = pos
	$Objects.call_deferred("add_child", new_object)

