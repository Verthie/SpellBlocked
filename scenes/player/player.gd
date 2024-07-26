extends CharacterBody2D

signal shoot(pos: Vector2, type: PackedScene, create: bool, direction: Vector2)

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0

# Pobieranie grawitacji z ustawień projektu
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _process(_delta):
	
	# Logika odpowiadająca za przyciski numeryczne (zmiana wartości globalnych aktualnego typu obiektu)
	if Input.is_action_just_pressed('switch_1'): Globals.current_object_type = 0
	if Input.is_action_just_pressed('switch_2'): Globals.current_object_type = 1
	if Input.is_action_just_pressed('switch_3'): Globals.current_object_type = 2
	if Input.is_action_just_pressed('switch_4'): Globals.current_object_type = 3

func _physics_process(delta: float) -> void:
	
	# Grawitacja
	if not is_on_floor():
		velocity.y += gravity * delta

	# Skakanie
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Kierunek ruchu, ruch lewo/prawo
	var direction = Input.get_axis("move_left", "move_rigt")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if Input.is_action_just_pressed('restart'):
		get_tree().reload_current_scene()
	
func _on_gun_shoot(pos: Vector2, type: PackedScene, create: bool) -> void:
	var player_direction = (get_global_mouse_position() - position).normalized()
	shoot.emit(pos, type, create, player_direction)

