extends CharacterBody2D

signal shoot(pos: Vector2, type: PackedScene, create: bool, direction: Vector2)

@export var foot_speed: float = 550
@export_range(0.0, 1.0, 0.025) var friction: float = 0.175
@export_range(0.0, 1.0, 0.025) var acceleration: float = 0.125

@export var jump_height: float = 150
@export var jump_time_to_peak: float = 0.25
@export var jump_time_to_descent: float = 0.5

@export var apex_threshold: float = 2
@export_range(0.0, 200.0, 0.1) var apex_gravity: float = 10.0
@export var apex_horizontal_boost: float = 20

@export var max_fall_speed: float = 800
@export var min_fall_speed: float = 20
@export var fall_acceleration: bool = false
@export var fall_acceleration_rate: float = 20

@onready var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity: float = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var apex_timer: Timer = $ApexTimer
@onready var gun: Area2D = $Gun

var fall_time: float = 0.0
var fall_multiplier: float = 1.0
var can_jump: bool = true
var was_on_floor: bool
var just_left_ledge: bool
var coyote: bool = false # Sprawdza czy postać znajduje się aktualnie w czasie coyote
var buffered_jump: bool = false # Sprawdza czy został zainicjowany buffer jump
var at_apex: bool = false
var is_jumping: bool = false
var can_shoot: bool = true

func _process(_delta):
	var object_amount = Globals.object_amounts[Globals.current_object_type]

	if gun.has_overlapping_bodies(): can_shoot = false
	else: can_shoot = true

	if Input.is_action_just_pressed('shoot_create') and can_shoot:
		if object_amount <= 0:
			print("no blocks")
		else:
			var scene: PackedScene = gun.get_scene('create')
			_shoot_emitter(true, scene)

	if Input.is_action_just_pressed('shoot_destroy') and can_shoot:
		var scene: PackedScene = gun.get_scene('destroy')
		_shoot_emitter(false, scene)

	if Input.is_action_just_pressed('restart'):
		get_tree().reload_current_scene()

	# Logika odpowiadająca za przyciski numeryczne (zmiana wartości globalnych aktualnego typu obiektu)
	if Input.is_action_just_pressed('switch_1'): Globals.current_object_type = 0
	if Input.is_action_just_pressed('switch_2'): Globals.current_object_type = 1
	if Input.is_action_just_pressed('switch_3'): Globals.current_object_type = 2
	if Input.is_action_just_pressed('switch_4'): Globals.current_object_type = 3

func _physics_process(delta: float) -> void:

	var direction: float = Input.get_axis("move_left", "move_rigt")

	handle_gravity(delta)

	handle_movement(direction)

	was_on_floor = is_on_floor() # Sprawdzanie czy postać była na podłodze przed wykonaniem ruchu

	#print("velocity.x: ", roundf(velocity.x) , " velocity.y: ", roundf(velocity.y))

	move_and_slide() # funkcja wprawiająca postać w ruch

	# Sprawdzanie czy postać spada bedąc uprzednio na podłożu
	just_left_ledge = !is_on_floor() and was_on_floor and velocity.y >= 0

	handle_coyote()

	handle_jump()

	handle_apex()

# Grawitacja
func handle_gravity(delta) -> void:
	if !is_on_floor():
		if at_apex:
			velocity.y = apex_gravity
		elif velocity.y < 0:
			velocity.y += jump_gravity * delta
		elif velocity.y >= 0:
			if !fall_acceleration:
				velocity.y += fall_gravity * delta # Liniowa akceleracja
			if fall_acceleration:
				fall_time += delta
				fall_multiplier = pow(fall_time * fall_acceleration_rate, 2)
				velocity.y += fall_gravity * fall_multiplier * delta # Nieliniowa akceleracja

		velocity.y = min(velocity.y, max_fall_speed) # Clamp prędkości spadania
		#print(" velocity.y: ", roundf(velocity.y))

	if fall_acceleration and is_on_floor():
		fall_time = 0.0
		fall_multiplier = 1.0

# Ruch horyzontalny
func handle_movement(direction) -> void:
	if direction != 0:
		velocity.x = lerp(velocity.x, direction * foot_speed, acceleration) # Akceleracja ruchu
	else:
		velocity.x = lerp(velocity.x, 0.0, friction) # Tarcie

	if at_apex:
		velocity.x += direction * apex_horizontal_boost

# Skakanie
func handle_jump() -> void:
	if can_jump == false and is_on_floor():
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

	if Input.is_action_just_released("jump") and velocity.y < jump_velocity / 2:
		velocity.y -= jump_velocity / 2

func handle_apex() -> void:
	if !at_apex and is_jumping and !is_on_floor() and abs(velocity.y) < apex_threshold:
		is_jumping = false
		at_apex = true
		apex_timer.start()

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

func _shoot_emitter(type_create: bool, scene: PackedScene) -> void:
	var pos: Vector2 = gun.get_shoot_marker()
	var player_direction: Vector2 = (get_global_mouse_position() - position).normalized()
	shoot.emit(pos, scene, type_create, player_direction)
