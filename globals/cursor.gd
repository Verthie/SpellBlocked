extends Area2D

const cursor_types: Dictionary = {"Block": 0, "Select": 4}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $'.'
@onready var created_timer: Timer = $CreatedTimer

@export var blacklist: Array[String]

var current_cursor_type: String = "Block"

var obstructed: bool = false
var object_index: int = 0
var colliding_body: Node
var cast_allowed: bool = false
var modification_allowed: bool = false
var just_created: bool = false

func _ready() -> void:
	EventBus.obstructed.connect(_change_obstructed_state)
	EventBus.changed_cursor_type.connect(_change_cursor_type)
	EventBus.block_removed.connect(_on_block_removed)
	EventBus.block_removal_rejected.connect(_play_not_available)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

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

		EventBus.cursor_changed_state.emit(colliding_body, cast_allowed, modification_allowed)

	#print(colliding_body, " ", cast_allowed, " ", modification_allowed)

	match current_cursor_type:
		"Select":
			handle_ui_sprite()
		"Block":
			if Globals.switching:
				obstructed = false
			else:
				handle_gameplay_sprite()
		_:
			if Globals.switching:
				obstructed = false
			else:
				handle_gameplay_sprite()

# Kolizja kursora z obiektami fizycznymi
func handle_collisions() -> void:
	var objects: Array[Node2D] = area_2d.get_overlapping_bodies()
	#print(objects)
	var objects_names: Array = objects.map(object_to_name)
	var objects_types: Array = objects.map(object_to_type)
	#print(objects_names)
	#print(objects_types)

	if "CharacterBody2D" in objects_types:
		cast_allowed = false
		object_index = objects_types.find("CharacterBody2D")
		colliding_body = objects[object_index]
		#var number_of_objects: int = objects_types.count("CharacterBody2D")
		#for object_index in range(number_of_objects):
			#var object = objects[object_index]
			#var block: Block
			#if object is Block:
				#block = object
			#if Globals.in_modify_state and !block.current_modifiers.has(Globals.current_block_type):
				#colliding_body = block
		modification_allowed = true if colliding_body is Block else false

	elif objects_names.any(check_in_blacklist):
		cast_allowed = false
		modification_allowed = false
		colliding_body = null

	else:
		cast_allowed = false
		modification_allowed = false
		colliding_body = null

	EventBus.cursor_changed_state.emit(colliding_body, cast_allowed, modification_allowed)

# Zmiana wyglądu kursora w trakcie przebywania w menu
func handle_ui_sprite() -> void:
	if Input.is_action_just_pressed('cast'):
		animation_player.play("select")

# Zmiana wyglądu kursora w trakcie gry
func handle_gameplay_sprite() -> void:

	if cast_allowed and Input.is_action_just_pressed('cast'):
		animation_player.play("cast_create")
		just_created = true
		created_timer.start()
	elif Globals.casting_disabled:
		return

	if obstructed:
		if Input.is_action_just_pressed('cast_destroy') or Input.is_action_just_pressed('cast'):
			_play_not_available()
	else:
		if modification_allowed and Input.is_action_just_pressed('cast') and Globals.in_modify_state:
			var block: Block = colliding_body
			if block.current_modifiers.size() < block.max_modifier_amount and Globals.current_block_type not in block.current_modifiers :
				animation_player.play("cast_create")
				AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_APPLY_MOD)
			else:
				_play_not_available()
		elif !just_created and (!cast_allowed and Input.is_action_just_pressed('cast')):
			_play_not_available()

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

# Funkcja przyjmująca tablicę obiektów i zwracająca tablicę nazw typów obiektów
func object_to_type(object: Node2D) -> String:
	return object.get_class()

func object_to_name(object: Node2D) -> String:
	return object.name

func check_in_blacklist(object_name: String) -> bool:
	return object_name in blacklist

func _on_timer_timeout() -> void:
	just_created = false

func _change_obstructed_state(state: bool) -> void:
	obstructed = state
	if obstructed:
		sprite_2d.self_modulate = Color(sprite_2d.self_modulate, 0.65)
	else:
		sprite_2d.self_modulate = Color(sprite_2d.self_modulate, 1)

func _change_cursor_type(type: String) -> void:
	current_cursor_type = type
	sprite_2d.frame = cursor_types[type]
	sprite_2d.self_modulate = Color(1,1,1)
	match type:
		"Select":
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			sprite_2d.position = Vector2(4, 4)
		"Block":
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
			sprite_2d.position = Vector2.ZERO

func _play_not_available() -> void:
	animation_player.play("not_available")
	AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_UNAVAILABLE)

func _on_block_removed() -> void:
	animation_player.play("cast_remove")
