extends CharacterBody2D
class_name Block

const DEFAULT_BLOCK_PHYSICS: CustomResource = preload('res://custom_scripts/default_block_physics.tres')
const ICE_BLOCK_PHYSICS: CustomResource = preload('res://custom_scripts/ice_block_physics.tres')
const LARGE_BLOCK_PHYSICS: CustomResource = preload('res://custom_scripts/large_block_physics.tres')

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var label: Label = $DebugLabel

@export_enum("None", "Ice", "Enlarge") var block_type: String = "None"

@export_category("Horizontal Movement")
@export_range(0.0, 1.0, 0.025) var friction: float = 0.175

@export_category("Gravity")
@export var max_fall_speed: float = 500
@export var gravity: float = 400

@export var fall_acceleration: bool = false
@export var fall_acceleration_rate: float = 20

var fall_time: float = 0.0
var fall_multiplier: float = 1.0

var block_thrown: bool = false
var falling: bool = false

var physics_resource: CustomResource
var applied_effect: bool = false

func _ready() -> void:
	EventBus.block_thrown.connect(apply_thrown_state)
	apply_effect(Globals.current_block_type)

func _physics_process(delta: float) -> void:

	apply_gravity(delta)

	push_blocks()

	if abs(velocity.x) < 0.1:
		remove_from_group('Pushed Block')
		label.text = "Not Pushed"
		block_thrown = false

	move_and_slide()

	if !ray_cast_2d.is_colliding() or ray_cast_2d.get_collider() is Block:
		apply_movement(Vector2(0.0,0.0), 0.0)


func apply_movement(direction: Vector2, speed: float) -> void:
	if direction.x != 0:
		velocity.x = direction.x * speed
		add_to_group('Pushed Block')
		label.text = "Pushed"
	else:
		velocity.x = lerp(velocity.x, 0.0, friction) # Tarcie

func apply_gravity(delta: float) -> void:

	if !is_on_floor():
		falling = true
		#if velocity.y >= 0:
		if !fall_acceleration:
			velocity.y += gravity * delta # Liniowa akceleracja
		if fall_acceleration:
			fall_time += delta
			fall_multiplier = pow(fall_time * fall_acceleration_rate, 2)
			velocity.y += gravity * fall_multiplier * delta # Nieliniowa akceleracja

		velocity.y = min(velocity.y, max_fall_speed) # Clamp prędkości spadania
	else:
		falling = false
		velocity.y = 0
		fall_time = 0

	if fall_acceleration and is_on_floor():
		fall_time = 0.0
		fall_multiplier = 1.0

func push_blocks() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var colliding_object: Object = collision.get_collider()
		#var collision_travel:  = collision.get_travel()
		#var collision_ramainder:  = collision.get_remainder()
		#print(collision.get_normal().y)
		if colliding_object is Block and abs(collision.get_normal().y) < 0.05:
			var colliding_block: Block = colliding_object
			if block_thrown:
				colliding_block.velocity.x = get_real_velocity().x/2
			else:
				colliding_block.velocity.x = velocity.x/(colliding_block.gravity/100)
			#print("real velocity:", get_real_velocity(), "normal:", collision.get_normal().y)
			#print("travel:", collision_travel, "ramainder:", collision_ramainder)

func apply_effect(effect_type: String) -> void:
	match effect_type:
		"Ice":
			# Low Friction
			physics_resource = ICE_BLOCK_PHYSICS
			sprite_2d.self_modulate = Color("6eecff") # ice color
		"Enlarge":
			# High Mass, High Friction, Rough True, Absorbent True
			physics_resource = LARGE_BLOCK_PHYSICS
			sprite_2d.self_modulate = Color("93969c")
		_:
			physics_resource = DEFAULT_BLOCK_PHYSICS
			sprite_2d.self_modulate = Color("ff836e") # standard color

	if !applied_effect:
		friction = physics_resource.friction
		gravity = physics_resource.gravity
		applied_effect = true
	else:
		gravity = max(gravity, physics_resource.gravity)


func destroy() -> void:
	queue_free()

func apply_thrown_state() -> void:
	block_thrown = true
