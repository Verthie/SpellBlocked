extends CharacterBody2D
class_name Player

@export var flip_on_start: bool = false

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

#@export var push_force: float = 15.0
#@export var min_push_force: float = 10.0

@onready var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity: float = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)

@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer: Timer = $Timers/JumpBufferTimer
@onready var apex_timer: Timer = $Timers/ApexTimer
@onready var flip_timer: Timer = $Timers/FlipTimer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wand_pivot: Marker2D = $Sprites/WandPivot
@onready var emote_animation: AnimationPlayer = $Sprites/Emotes/EmoteAnimation
@onready var shape_cast_2d: ShapeCast2D = $ShapeCast2D
@onready var light_source: PointLight2D = $LightSource

var current_state: String = "idle"
var animation_hold_states: Array = ["cast", "cast_remove", "land"]
var current_audio_stream: AudioStreamWAV

var mouse_direction: int

var last_velocity: Vector2 = Vector2.ZERO
var direction: float = 0.0
var fall_time: float = 0.0
var fall_multiplier: float = 1.0
var is_falling: bool = false

var can_jump: bool = true
var is_jumping: bool = false
var was_on_floor: bool
var just_left_ledge: bool
var forced_floor_state: bool = false
var can_fall_through: bool = false
var can_see_through: bool = false
var pushing: bool = false
var last_colliding_block: Block
var colliding_with_block: bool = false
var shape_collided: bool = false
var coyote: bool = false # Sprawdza czy postać znajduje się aktualnie w czasie coyote
var buffered_jump: bool = false # Sprawdza czy został zainicjowany buffer jump
var at_apex: bool = false
var can_flip: bool = true
var direction_locked: bool = false

var player_splashed: bool = false
var wand_enabled: bool = true

var animation_playing: bool = false

func _ready() -> void:
	EventBus.changed_interaction_state.connect(_on_interactable_state_change)
	$DeathArea.area_entered.connect(_on_player_death_experience)
	$DeathArea.body_entered.connect(_on_player_death_experience)
	if flip_on_start:
		flip_sprite(true)

func _process(_delta: float) -> void:

	if Globals.game_paused or Globals.playing_cutscene:
		return

	if !direction_locked:
		mouse_direction = 1 if get_local_mouse_position().x >= -0.125 else -1

	handle_animation()

	if !Globals.throwing_disabled:
		handle_direction_lock()
		check_top()

func set_state() -> String:
	var new_state: String = current_state

	#print(animation_playing)
	#if !Globals.player_lives:
		#new_state = "death"
	if !animation_playing:
		if is_on_floor() or shape_cast_2d.is_colliding():
			if direction == 0 and abs(velocity.x) <= 10:
				new_state = "idle"
			elif direction != 0 and (abs(velocity.x) > 10 or pushing):
				new_state = "run"

		if is_falling:
			new_state = "fall"
			if is_on_floor():
				new_state = "land"

		if is_jumping:
			new_state = "jump"

		if Globals.input_enabled and !Globals.casting_disabled:
			if Input.is_action_just_pressed("cast"):
				new_state = "cast"

			if Input.is_action_just_pressed("cast_destroy"):
				new_state = "cast_remove"
	elif current_state == "land":
		if Input.is_action_just_pressed("cast"):
			new_state = "cast"

		if Input.is_action_just_pressed("cast_destroy"):
			new_state = "cast_remove"

	return new_state

func handle_animation() -> void:

	handle_sprite_flip()

	if current_state != set_state():
		#print(current_state, " ", set_state())
		current_state = set_state()

		animation_player.play(current_state)

		if current_state in animation_hold_states:
			animation_playing = true
			await animation_player.animation_finished
			animation_playing = false

func handle_sprite_flip() -> void:
	if !direction_locked:
		if direction > 0:
			can_flip = false
			flip_sprite(false)
			flip_timer.start()
		elif direction < 0:
			can_flip = false
			flip_sprite(true)
			flip_timer.start()
		else:
			if can_flip:
				if mouse_direction == 1 and $Sprites/Wizard.flip_h:
					flip_sprite(false)
				elif mouse_direction == -1 and !$Sprites/Wizard.flip_h:
					flip_sprite(true)

func flip_sprite(state: bool = false) -> void:
	$Sprites/Wizard.flip_h = state
	wand_pivot.scale.x = 1 if !state else -1

func handle_direction_lock() -> void:

	if Input.is_action_pressed('direction_lock'):
		direction_locked = true

	if Input.is_action_just_released('direction_lock'):
		direction_locked = false

func handle_sound() -> void:
	match current_state:
		"land":
			if last_velocity.y > 400:
				AudioManager.create_audio(SoundEffectSettings.SoundEffectType.LAND)

func check_top() -> void:
	if shape_cast_2d.is_colliding():
		var colliding_object: Object = shape_cast_2d.get_collider(0)
		if colliding_object is Block:
			var throw_direction: int = -1 if $Sprites/Wizard.flip_h else 1
			var block: Block = colliding_object
			block.velocity.x = throw_direction * 300
			EventBus.block_thrown.emit()

func _physics_process(delta: float) -> void:

	if Globals.game_paused or Globals.playing_cutscene:
		return

	if Globals.input_enabled:
		direction = Input.get_axis("move_left", "move_right")
	else:
		direction = 0

	handle_gravity(delta)

	last_velocity = velocity

	handle_movement()

	handle_fall_through()

	was_on_floor = is_on_floor() # Sprawdzanie czy postać była na podłodze przed wykonaniem ruchu

	move_and_slide() # funkcja wprawiająca postać w ruch

	handle_push()

	just_left_ledge = !is_on_floor() and was_on_floor and velocity.y >= 0 # Sprawdzanie czy postać spada bedąc uprzednio na podłożu

	handle_coyote()

	if Globals.input_enabled:
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

			# preventing getting stuck in between blocks or walls
			if velocity.y > 25 and abs(get_position_delta().y) < 0.05:
				can_jump = true
				forced_floor_state = true
				#print('forced floor state')
				#print(velocity)
				#print(get_position_delta())

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
		if collider_type == "StaticBody2D" and collider.collision_layer == 128:
			can_fall_through = true
			can_see_through = true
		elif (collider_type == "AnimatableBody2D" and collider.collision_layer == 256) or (collider_type == "CharacterBody2D" and collider.collision_layer == 4):
			can_see_through = true
		else:
			can_fall_through = false
			can_see_through = false

	if Input.is_action_just_pressed("fall_through") and is_on_floor() and can_fall_through:
		#print(collider.collision_layer)
		#set_collision_mask_value(8, false)
		position.y += 1

	# Włączanie kolizji jak tylko gracz puści przycisk
	#if Input.is_action_just_released("fall_through"):
		#set_collision_mask_value(8, true)

func handle_push() -> void:

	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var colliding_object: Object = collision.get_collider()
		#print(colliding_object)
		if colliding_object is Block:
			var block: Block = colliding_object
			pushing = true
			last_colliding_block = block
			colliding_with_block = true
			if collision.get_normal().y == 0:
				block.apply_movement(-collision.get_normal(), (foot_speed/4))
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
	if can_jump == false and (is_on_floor() or forced_floor_state):
		if colliding_with_block and (last_colliding_block.falling == true or !last_colliding_block.jump_allowed):
			can_jump = false
		else:
			can_jump = true
		is_jumping = false

	if can_jump and (Input.is_action_just_pressed("jump") or buffered_jump) and (is_on_floor() or coyote or forced_floor_state):
		velocity.y = jump_velocity
		is_jumping = true
		can_jump = false
		buffered_jump = false
		forced_floor_state = false
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.JUMP)

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

func _on_flip_timer_timeout() -> void:
	can_flip = true

# Odtwarzanie animacji emotikony po przechwyceniu sygnału od obszaru (area2D)
func _on_interactable_state_change(in_area: bool) -> void:
	if in_area:
		emote_animation.play("interaction")
		emote_animation.queue("float")
	else:
		emote_animation.play_backwards("interaction")

func _on_player_death_experience(body: Node2D) -> void:
	if $DeathArea.has_overlapping_bodies():
		if body is LiquidTile:
			EventBus.object_splashed.emit(self, Vector2i(position), body)
		else:
			await get_tree().create_timer(0.2).timeout
	if $DeathArea.has_overlapping_bodies() or $DeathArea.has_overlapping_areas():
		Globals.input_enabled = false
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.HURT)
		EventBus.player_died.emit()
		animation_playing = true
		animation_player.play("death")
		await animation_player.animation_finished
		animation_playing = false
		#Globals.player_lives = false

func set_wand_sprite(state: bool = true) -> void:
	if state:
		$Sprites/WandPivot/Wand.show()
	else:
		$Sprites/WandPivot/Wand.hide()

func set_collisions(disable_collisions: bool = false) -> void:
	#$CollisionShape2D.disabled = disable_collisions
	$DeathArea/CollisionShape2D.disabled = disable_collisions
