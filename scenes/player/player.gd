extends CharacterBody2D

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
@onready var cast_timer: Timer = $CastTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wand_pivot: Marker2D = $Sprites/WandPivot
@onready var emote_animation: AnimationPlayer = $EmoteAnimation

var fall_time: float = 0.0
var fall_multiplier: float = 1.0
var is_falling: bool = false
var landed: bool = false
var can_jump: bool = true
var is_jumping: bool = false
var was_on_floor: bool
var just_left_ledge: bool
var coyote: bool = false # Sprawdza czy postać znajduje się aktualnie w czasie coyote
var buffered_jump: bool = false # Sprawdza czy został zainicjowany buffer jump
var at_apex: bool = false
var previous_state: String
var current_direction: String = "right"
var can_cast: bool = true
var casting: bool = false

func _process(_delta):

	var direction: float = Input.get_axis("move_left", "move_rigt")

	handle_animation(direction)

func handle_animation(direction) -> void:
	var animation_to_play: String = ""

	if direction > 0:
		$Sprites/Wizard.flip_h = false
		wand_pivot.scale.x = 1
	elif direction < 0:
		$Sprites/Wizard.flip_h = true
		wand_pivot.scale.x = -1

	if !casting:
		if is_on_floor():
			if previous_state == "falling":
				previous_state = "land"
				animation_to_play = "land"
			elif direction == 0 and previous_state != "land":
				animation_to_play = "idle"
			elif direction != 0 and previous_state != "land":
				animation_to_play = "run"

		if is_falling:
			animation_to_play = "fall"
			previous_state = "falling"

		if is_jumping:
			animation_to_play = "jump"

	if can_cast and Input.is_action_just_pressed("cast"):
		casting = true
		can_cast = false
		animation_to_play = "cast"
		cast_timer.start()

	animation_player.play(animation_to_play)

	if casting or previous_state == "land":
		await animation_player.animation_finished
		casting = false
		previous_state = "none"

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

func _on_cast_timer_timeout() -> void:
	can_cast = true

#TODO On signal emission from an area play a chosen emote animation which is given inside signal parameter

#func _on_gun_shoot(pos: Vector2, type: PackedScene, create: bool, direction: Vector2) -> void:
	#var projectile = scene.instantiate() as Area2D
	#projectile.position = pos
	#projectile.rotation_degrees = rad_to_deg(direction.angle())
	#projectile.direction = direction
	#projectile_direction = direction
	#if create: projectile.create.connect(_on_projectile_body_entered)
	#$Projectiles.add_child(projectile)
