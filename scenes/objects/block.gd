extends CharacterBody2D
class_name Block

#const ICE_BLOCK_PHYSICS: Resource = preload('res://custom_scripts/ice_bock_physics.tres')

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

@export_enum("None", "Ice", "Anti-Gravity", "Enlarge") var block_type: String = "None"

@export_category("Horizontal Movement")
@export_range(0.0, 1.0, 0.025) var friction: float = 0.175
@export_range(0.0, 1.0, 0.025) var acceleration: float = 0.125
@export_range(1.0, 100.0, 0.5) var starting_impulse: float = 1.0

@export_category("Gravity")
@export var max_fall_speed: float = 500
@export var gravity: float = 30

@export var fall_acceleration: bool = false
@export var fall_acceleration_rate: float = 20

var fall_time: float = 0.0
var fall_multiplier: float = 1.0

var physics_resource: CustomResource

func _ready() -> void:
	apply_effect(block_type)

func _physics_process(delta: float) -> void:

	apply_gravity(delta)

	push_blocks()

	move_and_slide()

	if velocity.x == 0:
		remove_from_group('Pushed Block')

	if !ray_cast_2d.is_colliding() or ray_cast_2d.get_collider() is Block:
		apply_movement(Vector2(0.0,0.0), 0.0)


func apply_movement(direction: Vector2, speed: float) -> void:
	if direction.x != 0:
		velocity.x = lerp(direction.x * starting_impulse, direction.x * speed, acceleration) # Akceleracja ruchu
		add_to_group('Pushed Block')
	else:
		velocity.x = lerp(velocity.x, 0.0, friction) # Tarcie

func apply_gravity(delta: float) -> void:

	if !is_on_floor():
		#if velocity.y >= 0:
		if !fall_acceleration:
			velocity.y += gravity * delta # Liniowa akceleracja
		if fall_acceleration:
			fall_time += delta
			fall_multiplier = pow(fall_time * fall_acceleration_rate, 2)
			velocity.y += gravity * fall_multiplier * delta # Nieliniowa akceleracja

		velocity.y = min(velocity.y, max_fall_speed) # Clamp prędkości spadania
	else:
		velocity.y = 0
		fall_time = 0

	if fall_acceleration and is_on_floor():
		fall_time = 0.0
		fall_multiplier = 1.0

func push_blocks() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var colliding_object: Object = collision.get_collider()
		if colliding_object is Block and collision.get_normal().y == 0:
			colliding_object.apply_movement(-collision.get_normal(), velocity.x/2)

func destroy() -> void:
	queue_free()

func apply_effect(effect_type: String) -> void:
	match effect_type:
		"Ice":
			# Standard Mass, Low Friction, Rough False, Absorbent False
			#physics_resource = ICE_BLOCK_PHYSICS
			sprite_2d.self_modulate = Color("6eecff") # ice color
			#mass = physics_resource.mass
			#physics_material_override.friction = physics_resource.mat.friction
		"Anti-Gravity":
			# Standard Mass, Low Gravity, Low Friction, Rough False, Absorbent False
			# Block needs to accelarate to the ceiling and not allow player to jump from it, maybe using it could disable the jump
			sprite_2d.self_modulate = Color("9985ff") # anti-gravity color
		"Enlarge":
			pass # High Mass, High Friction, Rough True, Absorbent True
		_:
			sprite_2d.self_modulate = Color("ff836e") # standard color
