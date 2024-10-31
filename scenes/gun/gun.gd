extends Area2D

const CREATE_PROJECTILE: PackedScene = preload('res://scenes/projectiles/create_projectile.tscn')
const DESTROY_PROJECTILE: PackedScene = preload('res://scenes/projectiles/destroy_projectile.tscn')

func _process(_delta: float) -> void:
	look_at(get_global_mouse_position())

##TODO Dwie różne strefy (Areas) dla różnego typu pocisków

## Mechanika strzelania pociskami
func get_shoot_marker() -> Vector2:
	var shoot_point: Marker2D = %ShootPoint
	return shoot_point.global_position

func get_scene(type: String) -> PackedScene:
	if type == 'create': return CREATE_PROJECTILE
	else: return DESTROY_PROJECTILE
