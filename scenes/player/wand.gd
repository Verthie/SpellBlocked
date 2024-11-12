extends Node2D

@onready var wand: Node2D = $'.'
@onready var sprite_2d: Sprite2D = $WandPivot/Sprite2D

#signal shoot(pos: Vector2, type: PackedScene, create: bool, direction: Vector2)
#
#const CREATE_PROJECTILE: PackedScene = preload('res://scenes/projectiles/create_projectile.tscn')
#const DESTROY_PROJECTILE: PackedScene = preload('res://scenes/projectiles/destroy_projectile.tscn')
#
#var can_shoot: bool = true

func _process(_delta: float) -> void:
	pass
	#var object_amount = Globals.object_amounts[Globals.current_object_type]
#
	#if gun.has_overlapping_bodies(): can_shoot = false
	#else: can_shoot = true
#
	#if Input.is_action_just_pressed('shoot_create') and can_shoot:
		#if object_amount <= 0:
			#print("no blocks")
		#else:
			#var scene: PackedScene = gun.get_scene('create')
			#_shoot_emitter(true, scene)
#
	#if Input.is_action_just_pressed('shoot_destroy') and can_shoot:
		#var scene: PackedScene = gun.get_scene('destroy')
		#_shoot_emitter(false, scene)

	#look_at(get_global_mouse_position())

##TODO Dwie różne strefy (Areas) dla różnego typu pocisków

#
#func get_scene(type: String) -> PackedScene:
	#if type == 'create': return CREATE_PROJECTILE
	#else: return DESTROY_PROJECTILE
#
#func _shoot_emitter(type_create: bool, scene: PackedScene) -> void:
	#var pos: Vector2 = gun.get_shoot_marker()
	#var player_direction: Vector2 = (get_global_mouse_position() - position).normalized()
	#shoot.emit(pos, scene, type_create, player_direction)
