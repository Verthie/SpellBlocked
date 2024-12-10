extends CharacterBody2D
class_name Block

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var label: Label = $DebugLabel
@onready var overlay: Sprite2D = $Sprite2D/Overlay

@onready var attributes: Node = $Attributes

@export_category("Horizontal Movement")
@export_range(0.0, 1.0, 0.025) var friction: float = 0.175

@export_category("Gravity")
@export var max_fall_speed: float = 500
@export var gravity: float = 400

@export var fall_acceleration: bool = false
@export var fall_acceleration_rate: float = 20

@export_category("Modifiers")
@export var modifier_nodes: Dictionary
@export var max_modifier_amount: int = 2

var fall_time: float = 0.0
var fall_multiplier: float = 1.0

var block_thrown: bool = false
var falling: bool = true

var current_modifiers: Array[String]

func _ready() -> void:
	EventBus.block_thrown.connect(apply_thrown_state)
	apply_modifier(Globals.current_block_type)

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

func apply_modifier(modifier_type: String) -> void:
	if current_modifiers.is_empty():
		apply_color(modifier_type)

	if modifier_type != "None" and modifier_type not in current_modifiers and current_modifiers.size() < max_modifier_amount:

		get_node(modifier_nodes[modifier_type]).apply(attributes)

		current_modifiers.append(modifier_type)

		if current_modifiers.size() == 2:
			apply_overlay(modifier_type)
			overlay.visible = true

func remove_latest_modifier() -> void:
	var latest_applied_modifier: String = current_modifiers.pop_back()
	if current_modifiers.is_empty():
		apply_color("None")
	else:
		apply_color(current_modifiers.back())
		overlay.visible = false

	get_node(modifier_nodes[latest_applied_modifier]).remove(attributes)

func apply_color(modifier_type: String) -> void:
	sprite_2d.self_modulate = Globals.block_properties[modifier_type].colour

func apply_overlay(modifier_type: String) -> void:
	overlay.self_modulate = Color(Globals.block_properties[modifier_type].colour, Globals.block_properties[modifier_type].modifier_overlay_opacity)

func destroy() -> void:
	queue_free()

func apply_thrown_state() -> void:
	block_thrown = true

func _on_attributes_friction_changed(new_friction: float) -> void:
	friction = new_friction

func _on_attributes_gravity_changed(new_gravity: float) -> void:
	gravity = new_gravity
