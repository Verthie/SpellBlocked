extends Area2D

const CREATE_PROJECTILE: PackedScene = preload('res://scenes/projectiles/create_projectile.tscn')
const DESTROY_PROJECTILE: PackedScene = preload('res://scenes/projectiles/destroy_projectile.tscn')

@onready var gun: Area2D = $'.'

signal shoot(pos: Vector2, type: PackedScene, create: bool)

var can_shoot: bool

func _process(_delta: float):
	look_at(get_global_mouse_position())
	
	var object_amount = Globals.object_amounts[Globals.current_object_type]
	
	if gun.has_overlapping_bodies(): can_shoot = false
	else: can_shoot = true
	
	# Mechanika strzelania pociskami
	if Input.is_action_just_pressed('shoot_create') and object_amount > 0 and can_shoot:
		var shoot_point: Marker2D = %ShootPoint
		shoot.emit(shoot_point.global_position, CREATE_PROJECTILE, true)
	#TODO Wyświetlić animację na ui przy próbie wystrzału, jeżeli ilość nie jest większa niż 0
	
	if Input.is_action_just_pressed('shoot_destroy') and can_shoot:
		var shoot_point: Marker2D = %ShootPoint
		shoot.emit(shoot_point.global_position, DESTROY_PROJECTILE, false)
