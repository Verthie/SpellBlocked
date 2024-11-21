extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $'.'

var current_body_type: String = "none"
var object_index: int = 0
var colliding_body: Node2D
var current_cursor_type: String = "block"
var cast_allowed: bool = false
var modification_allowed: bool = false

signal cursor_changed_state(colliding_body: Node2D, current_body_type: String, cast_allowed: bool, modification_allowed: bool)

func _ready() -> void:
	# TODO Ustawić połączenie z UI pod naciśnięcie przycisku - zmiana kursora
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta: float) -> void:
	area_2d.position = get_global_mouse_position()

	if area_2d.has_overlapping_bodies():
		handle_collisions()
	else:
		cast_allowed = true
		modification_allowed = false
		current_body_type = "none"
		colliding_body = null

		cursor_changed_state.emit(colliding_body, current_body_type, cast_allowed, modification_allowed)

	#print(colliding_body, " ", current_body_type, " ", cast_allowed, " ", modification_allowed)

	handle_sprite()

# Kolizja kursora z obiektami fizycznymi
func handle_collisions() -> void:
	var objects: Array[Node2D] = area_2d.get_overlapping_bodies()
	print(objects)
	var objects_types: Array = objects.map(object_to_type)
	#print(objects_types)

	if "RigidBody2D" in objects_types:
		### can't cast, can destroy and modify
		cast_allowed = false
		modification_allowed = true
		object_index = objects_types.find("RigidBody2D")
		current_body_type = "rigidbody"
		#print("Found RigidBody at index: ", object_index)
		colliding_body = objects[object_index]

	elif "TileMapLayer" or "CharacterBody2D" in objects_types:
		### can't cast, can't destroy and modify
		cast_allowed = false
		modification_allowed = false
		current_body_type = "none"
		colliding_body = null

	cursor_changed_state.emit(colliding_body, current_body_type, cast_allowed, modification_allowed)

# Zmiana wyglądu kursora
func handle_sprite() -> void:

	if (!cast_allowed and Input.is_action_just_pressed('cast')) or (!modification_allowed and Input.is_action_just_pressed('cast_destroy')):
		animation_player.play("not_available")

	if !animation_player.is_playing():
		if !cast_allowed:
			sprite_2d.frame = 5
		else:
			match current_cursor_type:
				"block":
					sprite_2d.frame = 0
				"anti-gravity":
					sprite_2d.frame = 1
				"ice":
					sprite_2d.frame = 2
				"enlarge":
					sprite_2d.frame = 3
				"shrink":
					sprite_2d.frame = 4
				"select":
					sprite_2d.frame = 10
				"type":
					sprite_2d.frame = 11
				_:
					sprite_2d.frame = 0

# Funkcja przyjmująca tablicę obiektów i zwracająca tablicę nazw typów obiektów
func object_to_type(object: Node2D) -> String:
	return object.get_class()
