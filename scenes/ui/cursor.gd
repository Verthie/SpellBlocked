extends Node2D

signal cursor_changed_state(colliding_body: Node, cast_allowed: bool, modification_allowed: bool)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $'.'
@onready var created_timer: Timer = $CreatedTimer

@export_enum("Block", "Grow", "Shrink", "Select", "Type") var current_cursor_type: String = "Block"
@export var blacklist: Array[String]

var obstructed: bool = false
var object_index: int = 0
var colliding_body: Node
var cast_allowed: bool = false
var modification_allowed: bool = false
var just_created: bool = false

func _ready() -> void:
	# TODO Ustawić połączenie z UI pod naciśnięcie przycisku - zmiana kursora
	EventBus.obstructed.connect(change_obstructed_state)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta: float) -> void:
	area_2d.position = get_global_mouse_position()

	if area_2d.has_overlapping_bodies():
		handle_collisions()
	else:
		if !obstructed and Globals.block_amount > 0:
			cast_allowed = true
		else:
			cast_allowed = false
		modification_allowed = false
		colliding_body = null

		cursor_changed_state.emit(colliding_body, cast_allowed, modification_allowed)

	#print(colliding_body, " ", cast_allowed, " ", modification_allowed)

	handle_sprite()

# Kolizja kursora z obiektami fizycznymi
func handle_collisions() -> void:
	var objects: Array[Node2D] = area_2d.get_overlapping_bodies()
	#print(objects)
	var objects_names: Array = objects.map(object_to_name)
	var objects_types: Array = objects.map(object_to_type)
	#print(objects_names)
	#print(objects_types)

	if objects_names.any(check_in_blacklist):
		cast_allowed = false
		modification_allowed = false
		colliding_body = null

	elif "CharacterBody2D" in objects_types:
		cast_allowed = false
		object_index = objects_types.find("CharacterBody2D")
		colliding_body = objects[object_index]
		modification_allowed = true if colliding_body is Block else false

	cursor_changed_state.emit(colliding_body, cast_allowed, modification_allowed)

# Zmiana wyglądu kursora
func handle_sprite() -> void:

	if cast_allowed and Input.is_action_just_pressed('cast'):
		animation_player.play("cast_create")
		just_created = true
		created_timer.start()

	if modification_allowed and Input.is_action_just_pressed('cast_destroy'):
		animation_player.play("cast_remove")
	elif modification_allowed and Input.is_action_just_pressed('cast') and Globals.in_modify_state:
		var block: Block = colliding_body
		if block.current_modifiers.size() < block.max_modifier_amount and Globals.current_block_type not in block.current_modifiers :
			animation_player.play("cast_create")
		else:
			animation_player.play("not_available")
	elif !just_created and (!cast_allowed and Input.is_action_just_pressed('cast')) or (!modification_allowed and Input.is_action_just_pressed('cast_destroy')):
		animation_player.play("not_available")

	if !animation_player.is_playing():
		if Globals.in_modify_state:
			if (!modification_allowed and area_2d.has_overlapping_bodies()) or obstructed:
				sprite_2d.self_modulate = Color("df989f")
			else:
				sprite_2d.self_modulate = Globals.block_properties[Globals.current_block_type].colour
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

func check_in_blacklist(object_name: String) -> bool:
	return object_name in blacklist

func _on_timer_timeout() -> void:
	just_created = false

func change_obstructed_state(state: bool) -> void:
	obstructed = state
