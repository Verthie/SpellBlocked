extends CharacterBody2D

signal shoot(pos: Vector2, type: PackedScene, create: bool, direction: Vector2)

@export var max_speed: float = 550
@export_range(0.0, 1.0, 0.025) var friction: float = 0.175
@export_range(0.0, 1.0, 0.025) var acceleration: float = 0.125

@export var gravity: float = 3000
@export var apex_threshold: float = 2
@export_range(1.0, 200.0, 0.5) var apex_gravity: float = 15
@export var apex_horizontal_boost: float = 20
@export var jump_speed: float = -800

@export var fall_speed: float = 1000
@export_range(1.0, 50.0) var fall_acceleration: float = 2
@export var max_fall_speed: float = 1000
@export var min_fall_speed: float = 50

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

var can_jump: bool = true
var was_on_floor: bool
var just_left_ledge: bool
var coyote: bool = false # Sprawdza czy postać znajduje się aktualnie w czasie coyote
var buffered_jump: bool = false # Sprawdza czy został zainicjowany buffer jump
var default_fall_speed: float = fall_speed

@onready var gun: Area2D = $Gun

var can_shoot: bool

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

	handle_apex(direction)

# Grawitacja
func handle_gravity(delta) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y += gravity * delta
		else:
			velocity.y = lerp(velocity.y, fall_speed, fall_acceleration * delta) # Interpolacja liniowa od obecnego velocity.y do fall_speed

		velocity.y = min(velocity.y, max_fall_speed) # Clamp prędkości spadania
		#print(" velocity.y: ", roundf(velocity.y))
		#print(" gravity: ", roundf(gravity * delta))

# Ruch horyzontalny
func handle_movement(direction) -> void:
	if direction != 0:
		velocity.x = lerp(velocity.x, direction * max_speed, acceleration) # Akceleracja ruchu
	else:
		velocity.x = lerp(velocity.x, 0.0, friction) # Tarcie

# Skakanie
func handle_jump() -> void:
	if can_jump == false and is_on_floor():
		can_jump = true

	if can_jump and (Input.is_action_just_pressed("jump") or buffered_jump) and (is_on_floor() or coyote):
		velocity.y = jump_speed
		can_jump = false
		buffered_jump = false

	if !is_on_floor() and Input.is_action_just_pressed('jump'):
		jump_buffer_timer.start()
		buffered_jump = true

	if Input.is_action_just_released("jump") and velocity.y < jump_speed / 2:
		velocity.y -= jump_speed / 2

func handle_apex(direction) -> void:
	if !is_on_floor() and abs(velocity.y) <= apex_threshold:
		velocity.x += direction * apex_horizontal_boost
		fall_speed = apex_gravity + apex_threshold
	else:
		fall_speed = default_fall_speed

func handle_coyote() -> void:
	if just_left_ledge:
		coyote_timer.start()
		coyote = true

func _on_coyote_timer_timeout() -> void:
	coyote = false

func _on_buffered_timer_timeout() -> void:
	buffered_jump = false

func _shoot_emitter(type_create: bool, scene: PackedScene) -> void:
	var pos: Vector2 = gun.get_shoot_marker()
	var player_direction: Vector2 = (get_global_mouse_position() - position).normalized()
	shoot.emit(pos, scene, type_create, player_direction)
