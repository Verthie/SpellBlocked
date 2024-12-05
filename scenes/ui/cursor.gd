extends Node2D

signal cursor_changed_state(colliding_body: Node2D, current_body_type: String, cast_allowed: bool, modification_allowed: bool)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $'.'
@onready var created_timer: Timer = $CreatedTimer

@export_enum("Block", "Grow", "Shrink", "Select", "Type") var current_cursor_type: String = "Block"

var current_body_type: String = "none"
var object_index: int = 0
var colliding_body: Node2D
var cast_allowed: bool = false
var modification_allowed: bool = false
var just_created: bool = false

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
	#print(objects)
	var objects_names: Array = objects.map(object_to_name)
	var objects_types: Array = objects.map(object_to_type)
	#print(objects_names)
	#print(objects_types)

	if "FGFirstPlane" in objects_names or "Player" in objects_names:
		### can't cast, can't destroy and modify
		cast_allowed = false
		modification_allowed = false
		current_body_type = "none"
		colliding_body = null

	elif "CharacterBody2D" in objects_types:
		### can't cast, can destroy and modify
		cast_allowed = false
		modification_allowed = true
		object_index = objects_types.find("CharacterBody2D")
		current_body_type = "characterbody"
		#print("Found RigidBody at index: ", object_index)
		colliding_body = objects[object_index]

	cursor_changed_state.emit(colliding_body, current_body_type, cast_allowed, modification_allowed)

# Zmiana wyglądu kursora
func handle_sprite() -> void:

	if cast_allowed and Input.is_action_just_pressed('cast'):
		animation_player.play("cast_create")
		just_created = true
		created_timer.start()

	if modification_allowed and Input.is_action_just_pressed('cast_destroy'):
		animation_player.play("cast_remove")
	elif (!cast_allowed and Input.is_action_just_pressed('cast')) or (!modification_allowed and Input.is_action_just_pressed('cast_destroy')):
		animation_player.play("not_available")

	if !animation_player.is_playing():
		if Globals.in_modify_state:
			match Globals.current_block_type:
				"Ice":
					sprite_2d.self_modulate = Color("93f0ff")
				"Enlarge":
					sprite_2d.self_modulate = Color("93969c")
				_:
					sprite_2d.self_modulate = Color(0,0,0)
			if !modification_allowed and area_2d.has_overlapping_bodies():
				sprite_2d.self_modulate = Color("df989f")
		elif cast_allowed or just_created:
			sprite_2d.self_modulate = Color(1,1,1)
		elif !cast_allowed and !Globals.in_modify_state:
			sprite_2d.self_modulate = Color("df989f")


	match Globals.current_cursor_type:
		"Block":
			sprite_2d.frame = 0
		"Grow":
			sprite_2d.frame = 2
		"Shrink":
			sprite_2d.frame = 3
		"Select":
			sprite_2d.frame = 4
		"Type":
			sprite_2d.frame = 5
		_:
			sprite_2d.frame = 0

# Funkcja przyjmująca tablicę obiektów i zwracająca tablicę nazw typów obiektów
func object_to_type(object: Node2D) -> String:
	return object.get_class()

func object_to_name(object: Node2D) -> String:
	return object.name

func _on_timer_timeout() -> void:
	just_created = false
