extends CharacterBody2D
class_name Player

@export var foot_speed: float = 140
@export_range(0.0, 1.0, 0.025) var friction: float = 0.175
@export_range(0.0, 1.0, 0.025) var acceleration: float = 0.125

@export var jump_height: float = 30
@export var jump_time_to_peak: float = 0.3
@export var jump_time_to_descent: float = 0.2

@export var apex_threshold: float = 2
@export_range(0.0, 200.0, 0.1) var apex_gravity: float = 10.0
@export var apex_horizontal_boost: float = 2

@export var max_fall_speed: float = 500
@export var fall_acceleration: bool = false
@export var fall_acceleration_rate: float = 20

@export var push_force: float = 15.0
@export var min_push_force: float = 10.0

@onready var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity: float = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var apex_timer: Timer = $ApexTimer
@onready var cast_timer: Timer = $CastTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wand_pivot: Marker2D = $Sprites/WandPivot
@onready var emote_animation: AnimationPlayer = $Sprites/Emotes/EmoteAnimation
@onready var shape_cast_2d: ShapeCast2D = $ShapeCast2D

var direction: float = 0.0
var fall_time: float = 0.0
var fall_multiplier: float = 1.0
var is_falling: bool = false
var landed: bool = false
var can_jump: bool = true
var is_jumping: bool = false
var was_on_floor: bool
var just_left_ledge: bool
var last_colliding_block: Block
var colliding_with_block: bool = false
var shape_collided: bool = false
var coyote: bool = false # Sprawdza czy postać znajduje się aktualnie w czasie coyote
var buffered_jump: bool = false # Sprawdza czy został zainicjowany buffer jump
var at_apex: bool = false
var previous_state: String
var can_cast: bool = true
var casting: bool = false

func _ready() -> void:
	EventBus.changed_interaction_state.connect(_on_interactable_state_change)

func _process(_delta: float) -> void:

	handle_animation()

	check_top()

func handle_animation() -> void:
	var animation_to_play: String = ""

	if get_local_mouse_position().x >= -0.125:
		$Sprites/Wizard.flip_h = false
		wand_pivot.scale.x = 1
	else:
		$Sprites/Wizard.flip_h = true
		wand_pivot.scale.x = -1

	if !casting:
		if is_on_floor() and animation_player.current_animation != "land":
			if direction == 0:
				animation_to_play = "idle"
			elif direction != 0 and animation_player.current_animation != "run":
				animation_to_play = "run"

		if is_falling:
			animation_to_play = "fall"
			if is_on_floor():
				animation_to_play = "land"

		if is_jumping:
			animation_to_play = "jump"

	if can_cast and !casting and Input.is_action_just_pressed("cast"):
		casting = true
		can_cast = false
		animation_to_play = "cast"
		cast_timer.start()

	if can_cast and !casting and Input.is_action_just_pressed("cast_destroy"):
		casting = true
		can_cast = false
		animation_to_play = "cast_remove"
		cast_timer.start()

	animation_player.play(animation_to_play)

	if casting:
		await animation_player.animation_finished
		casting = false

func check_top() -> void:
	if shape_cast_2d.is_colliding():
		var mouse_direction: int = 1 if get_local_mouse_position().x >= -0.125 else -1
		var colliding_object: Object = shape_cast_2d.get_collider(0)
		if colliding_object is Block:
			var block: Block = colliding_object
			block.velocity.x = mouse_direction * 300
			EventBus.block_thrown.emit()

func _physics_process(delta: float) -> void:

	direction = Input.get_axis("move_left", "move_right")

	#if Input.is_action_pressed('move_left'):
		#direction = -1
	#elif Input.is_action_pressed('move_right'):
		#direction = 1
	#elif Input.is_action_just_released('move_left') or Input.is_action_just_released('move_right'):
		#direction = 0

	handle_gravity(delta)

	handle_movement()

	handle_fall_through()

	was_on_floor = is_on_floor() # Sprawdzanie czy postać była na podłodze przed wykonaniem ruchu

	move_and_slide() # funkcja wprawiająca postać w ruch

	handle_push()

	just_left_ledge = !is_on_floor() and was_on_floor and velocity.y >= 0 # Sprawdzanie czy postać spada bedąc uprzednio na podłożu

	handle_coyote()

	handle_jump()

	#handle_edge_detection()

	handle_apex()

# Grawitacja
func handle_gravity(delta: float) -> void:

	if !is_on_floor():
		if at_apex:
			velocity.y = apex_gravity
		elif velocity.y < 0:
			velocity.y += jump_gravity * delta
		elif velocity.y >= 0:
			is_falling = true
			if !fall_acceleration:
				velocity.y += fall_gravity * delta # Liniowa akceleracja
			if fall_acceleration:
				fall_time += delta
				fall_multiplier = pow(fall_time * fall_acceleration_rate, 2)
				velocity.y += fall_gravity * fall_multiplier * delta # Nieliniowa akceleracja

		velocity.y = min(velocity.y, max_fall_speed) # Clamp prędkości spadania
		#print(" velocity.y: ", roundf(velocity.y))
	else:
		is_falling = false

	if fall_acceleration and is_on_floor():
		fall_time = 0.0
		fall_multiplier = 1.0

# Ruch horyzontalny
func handle_movement() -> void:
	if direction != 0:
		velocity.x = lerp(velocity.x, direction * foot_speed, acceleration) # Akceleracja ruchu
	else:
		velocity.x = lerp(velocity.x, 0.0, friction) # Tarcie

	if at_apex:
		velocity.x += direction * apex_horizontal_boost

# Funkcja spadania przez platformy fall-through
func handle_fall_through() -> void:
	var last_collision: KinematicCollision2D
	var collider: Object
	var collider_type: String = ""

	if get_last_slide_collision() != null:
		last_collision = get_last_slide_collision()
		collider = last_collision.get_collider()
		collider_type = collider.get_class() if collider != null else ""

	if Input.is_action_just_pressed("fall_through") and is_on_floor() and collider_type == "StaticBody2D":
		#print(collider.collision_layer)
		#set_collision_mask_value(8, false)
		position.y += 1 if collider.collision_layer == 128 else 0

	# Włączanie kolizji jak tylko gracz puści przycisk
	#if Input.is_action_just_released("fall_through"):
		#set_collision_mask_value(8, true)

func handle_push() -> void:

	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var colliding_object: Object = collision.get_collider()
		#print(colliding_object)
		if colliding_object is Block:
			last_colliding_block = colliding_object
			colliding_with_block = true
			if collision.get_normal().y == 0:
				colliding_object.apply_movement(-collision.get_normal(), (foot_speed/5))
		else:
			colliding_with_block = false

	var moving_blocks: Array[Node] = get_tree().get_nodes_in_group('Pushed Block')
	for block: Block in moving_blocks:
		var all_collisions: Array[Object]
		for i: int in block.get_slide_collision_count():
			var collision: KinematicCollision2D = block.get_slide_collision(i)
			var colliding_object: Object = collision.get_collider()
			all_collisions.append(colliding_object)
		if Player not in all_collisions:
			block.apply_movement(Vector2(0.0,0.0), 0.0)

# Skakanie
func handle_jump() -> void:
	if can_jump == false and is_on_floor():
		if colliding_with_block and last_colliding_block.falling == true:
			can_jump = false
		else:
			can_jump = true
		is_jumping = false

	if can_jump and (Input.is_action_just_pressed("jump") or buffered_jump) and (is_on_floor() or coyote):
		velocity.y = jump_velocity
		is_jumping = true
		can_jump = false
		buffered_jump = false

	if !is_on_floor() and Input.is_action_just_pressed('jump'):
		jump_buffer_timer.start()
		buffered_jump = true

	if Input.is_action_just_released("jump") and velocity.y < jump_velocity / 2.5:
		velocity.y -= jump_velocity / 2

# Niezaimplementowana funkcja detekcji krawędzi i korekty gracza
func handle_edge_detection() -> void:
	if is_jumping and get_last_slide_collision() != null:
		#var nudge_vertical_value: float = 100.0
		#var nudge_horizontal_value: float = 50.0

		var hit_position: Vector2 = get_last_slide_collision().get_position() # Punkt w którym dwa obiekty wpadły w kolizję
		var dir: Vector2 = position - hit_position
		position += dir.normalized() * velocity.x
		#print("dir:", dir, " ", dir.normalized())
		#print(dir.normalized())

# Funkcja wykonana w trakcie docierania do górnej granicy skoku
func handle_apex() -> void:
	if !at_apex and is_jumping and !is_on_floor() and abs(velocity.y) < apex_threshold:
		is_jumping = false
		at_apex = true
		apex_timer.start()

# Funkcja implementująca czas coyote
func handle_coyote() -> void:
	if just_left_ledge:
		coyote_timer.start()
		coyote = true

func _on_coyote_timer_timeout() -> void:
	coyote = false

func _on_buffered_timer_timeout() -> void:
	buffered_jump = false

func _on_apex_timer_timeout() -> void:
	at_apex = false

func _on_cast_timer_timeout() -> void:
	can_cast = true

# Odtwarzanie animacji emotikony po przechwyceniu sygnału od obszaru (area2D)
func _on_interactable_state_change(in_area: bool) -> void:
	if in_area:
		emote_animation.play("interaction")
		emote_animation.queue("float")
	else:
		emote_animation.play_backwards("interaction")


func _on_area_2d_body_entered(_body: Node2D) -> void:
	get_tree().call_deferred("reload_current_scene")
