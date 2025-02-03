extends CharacterBody2D
class_name Block

#signal body_on_button

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var shape_cast_down: ShapeCast2D = $ShapeCastDown
@onready var label: Label = $DebugLabel
@onready var overlay: Sprite2D = $Sprite2D/Overlay
@onready var anti_gravity_top: ShapeCast2D = $'Anti-GravityTop'

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

@export_enum("None", "Ice", "Stone", "Gravity") var starting_modifier: String = "None"

var last_velocity: Vector2 = Vector2.ZERO

var fall_time: float = 0.0
var fall_multiplier: float = 1.0

var jump_allowed: bool = true

var block_thrown: bool = false
var falling: bool = true

var current_modifiers: Array[String]

var reversed_gravity: bool = false

var object_on_top: Object

func _ready() -> void:
	EventBus.block_thrown.connect(apply_thrown_state)
	apply_modifier(Globals.current_block_type)
	if starting_modifier != "None":
		apply_modifier(starting_modifier)
	$SplashArea.area_entered.connect(_on_block_destruction)
	$SplashArea.body_entered.connect(_on_block_destruction)

func _process(_delta: float) -> void:

	handle_sound()

	last_velocity = velocity

func handle_sound() -> void:
	if is_on_floor():
		if last_velocity.y > 200:
			AudioManager.create_2d_audio_at_location(position, SoundEffectSettings.SoundEffectType.BLOCK_LAND)
		elif last_velocity.y > 50:
			AudioManager.create_2d_audio_at_location(position, SoundEffectSettings.SoundEffectType.BLOCK_LAND_QUIET)

func _physics_process(delta: float) -> void:

	apply_gravity(delta)

	push_blocks()

	if abs(velocity.x) < 0.1:
		remove_from_group('Pushed Block')
		label.text = "Not Pushed"
		block_thrown = false

	move_and_slide()

	apply_movement(Vector2(0,0), 0)

	if shape_cast_down.is_colliding():
		var collision_object: Object = shape_cast_down.get_collider(0)
		if collision_object is Block:
			var block: Block = collision_object
			if "Gravity" in block.current_modifiers:
				jump_allowed = false
			else:
				jump_allowed = true
		else:
			jump_allowed = true

	if anti_gravity_top.is_colliding():
		object_on_top = anti_gravity_top.get_collider(0)
		if velocity.y < 0 and object_on_top is Player:
			velocity.y = 0
		if shape_cast_down.is_colliding() and shape_cast_down.get_collider(0) is Block and object_on_top is Block: # block is between two blocks
			velocity.y = 0


func apply_movement(direction: Vector2, speed: float) -> void:
	if direction.x != 0:
		velocity.x = direction.x * speed
		add_to_group('Pushed Block')
		label.text = "Pushed"
	else:
		velocity.x = lerp(velocity.x, 0.0, friction) # Tarcie

func apply_gravity(delta: float) -> void:
	if "Gravity" in current_modifiers:
		reversed_gravity = true
	else:
		reversed_gravity = false

	if !is_on_floor():
		falling = true
		#if velocity.y >= 0:
		if !fall_acceleration:
			if "Gravity" not in current_modifiers:
				velocity.y += gravity * delta # Liniowa akceleracja
			elif "Gravity" in current_modifiers:
				if anti_gravity_top.is_colliding():
					velocity.y += -gravity * delta * 2
				else:
					velocity.y += gravity * delta
		else:
			fall_time += delta
			fall_multiplier = pow(fall_time * fall_acceleration_rate, 2)
			velocity.y += gravity * fall_multiplier * delta # Nieliniowa akceleracja

		velocity.y = min(velocity.y, max_fall_speed) # Clamp prędkości spadania
	else:
		falling = false
		if !reversed_gravity:
			velocity.y = 0
		else:
			velocity.y += gravity * delta
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
		if colliding_object is Block and (abs(collision.get_normal().y) < 0.05 and abs(collision.get_normal().y) > 0):
			var colliding_block: Block = colliding_object
			if block_thrown:
				colliding_block.velocity.x = get_real_velocity().x/1.5
			else:
				colliding_block.velocity.x = velocity.x/(colliding_block.gravity/100)
			#print("real velocity:", get_real_velocity(), "normal:", collision.get_normal().y)
			#print("travel:", collision_travel, "ramainder:", collision_ramainder)
		#if colliding_object is PressureButton:
			#body_on_button.emit()

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
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSettings.SoundEffectType.CAST_DESTROY)
	queue_free()

func apply_thrown_state() -> void:
	block_thrown = true

func _on_block_destruction(body: Node2D) -> void:
	if body is LiquidTile:
		EventBus.object_splashed.emit(self, Vector2i(position), body)

func _on_attributes_friction_changed(new_friction: float) -> void:
	friction = new_friction

func _on_attributes_gravity_changed(new_gravity: float) -> void:
	gravity = new_gravity
