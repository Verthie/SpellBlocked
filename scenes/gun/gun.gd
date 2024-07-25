extends Node2D

const CREATE_PROJECTILE: PackedScene = preload('res://scenes/projectiles/create_projectile.tscn')
const DESTROY_PROJECTILE: PackedScene = preload('res://scenes/projectiles/destroy_projectile.tscn')

signal shoot(pos: Vector2, type: PackedScene, create: bool)

func _process(_delta: float):
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed('shoot_create'):
		var shoot_point: Marker2D = %ShootPoint
		shoot.emit(shoot_point.global_position, CREATE_PROJECTILE, true)
	
	if Input.is_action_just_pressed('shoot_destroy'):
		var shoot_point: Marker2D = %ShootPoint
		shoot.emit(shoot_point.global_position, DESTROY_PROJECTILE, false)
