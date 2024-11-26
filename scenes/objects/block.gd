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

@export var allow_staying_on_player_head: bool = false

var fall_time: float = 0.0
var fall_multiplier: float = 1.0

var pushing: bool = false
var predetermined_direction: int

var player: Player
var on_head_block: bool = false
#var on_top_of_block: bool = false
#var on_top_of_player: bool = false

var physics_resource: CustomResource

func _ready() -> void:
	predetermined_direction = randi() % 2
	apply_effect(block_type)

func _physics_process(delta: float) -> void:

	apply_gravity(delta)

	push_blocks()

	move_and_slide()

	if velocity.x == 0:
		remove_from_group('Pushed Block')

	if ray_cast_2d.is_colliding():
		if Globals.player_has_block_on_head or (!allow_staying_on_player_head and ray_cast_2d.get_collider() is Player):
			slide_from_head()
		elif allow_staying_on_player_head:
			check_below()

	if !ray_cast_2d.is_colliding() or ray_cast_2d.get_collider() is Block:
		apply_movement(Vector2(0.0,0.0), 0.0)

	if Globals.player_has_block_on_head and on_head_block:
		var tween = create_tween().bind_node(self).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", Vector2(player.position.x, player.position.y - 12), 0.2)


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
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var colliding_object: Object = collision.get_collider()
		#print(colliding_object)
		if colliding_object is Block and collision.get_normal().y == 0:
			colliding_object.apply_movement(-collision.get_normal(), velocity.x/2)

	# Ilość bloków powinna wpływać na to jak bardzo są one przesuwane przez kolejne bloki (podzielimy prędkość przez ilość bloków w kolizji)

func check_below() -> void:
	var colliding_object: Object = ray_cast_2d.get_collider()
	if colliding_object is Player:
		print("colliding with Player")
		player = colliding_object
		if position.x != player.position.x:
			var tween = create_tween().bind_node(self).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "position", Vector2(player.position.x, player.position.y - 12), 0.2)
			set_collision_layer_value(3, false)
			Globals.player_has_block_on_head = true
			on_head_block = true

func slide_from_head() -> void:
	if ray_cast_2d.is_colliding():
		if ray_cast_2d.get_collider() is Player:
			var direction: float = 1.0 if predetermined_direction else -1.0
			velocity.x += 10 * direction


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
