extends CharacterBody2D

signal shoot(pos: Vector2, type: PackedScene, create: bool, direction: Vector2)

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_rigt")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
func _on_gun_shoot(pos: Vector2, type: PackedScene, create: bool) -> void:
	var player_direction = (get_global_mouse_position() - position).normalized()
	shoot.emit(pos, type, create, player_direction)
