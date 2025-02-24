extends Area2D

const cursor_types: Dictionary = {"Block": 0, "Select": 4}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var action_timer: Timer = $ActionTimer
@onready var light_source: PointLight2D = $LightSource
@onready var obstruction_area: Area2D = $ObstructionArea

@export var blacklist: Array[String]

var current_cursor_type: String = "Block"
var current_cursor_color: Color = Color('ffffff')

var obstructed: bool = false
var object_index: int = 0
var colliding_body: Node
var cast_allowed: bool = false
var modification_allowed: bool = false
var just_made_action: bool = false
var modulate_swap: bool = false
var mouse_enabled: bool = true

func _ready() -> void:
	EventBus.obstructed.connect(_change_obstructed_state)
	EventBus.changed_cursor_type.connect(_change_cursor_type)
	EventBus.casted.connect(_play_block_cast)
	EventBus.applied_modification.connect(_play_block_cast.unbind(2))
	EventBus.removed_modification.connect(_play_block_cast.unbind(1))
	EventBus.block_removed.connect(_on_block_removed.unbind(1))
	EventBus.block_action_rejected.connect(_play_not_available)
	EventBus.game_restarted.connect(_set_initial_values)
	animation_player.animation_finished.connect(_reset_cursor_color.unbind(1))
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func _input(event: InputEvent) -> void:
	if current_cursor_type == "Select":
		if event.is_action_pressed('cast'):
			animation_player.play("select")
	elif current_cursor_type == "Block" and Globals.casting_disabled:
		if event.is_action_pressed('cast'):
			_play_block_cast()

func _process(_delta: float) -> void:

	if mouse_enabled:
		position = get_global_mouse_position()

	if has_overlapping_bodies():
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

	if Globals.switching:
		obstructed = false

# Kolizja kursora z obiektami fizycznymi
func handle_collisions() -> void:
	var objects: Array[Node2D] = get_overlapping_bodies()
	var objects_types: Array = objects.map(object_to_type)
	#print(objects)
	#var objects_names: Array = objects.map(object_to_name)
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

	#elif objects_names.any(check_in_blacklist):
		#cast_allowed = false
		#modification_allowed = false
		#colliding_body = null

	else:
		cast_allowed = false
		modification_allowed = false
		colliding_body = null

	EventBus.cursor_changed_state.emit(colliding_body, cast_allowed, modification_allowed)

# Zmiana wyglądu kursora w trakcie gry
func handle_gameplay_sprite() -> void:

	if Globals.casting_disabled:
		return

	if !animation_player.is_playing():
		if Globals.in_modify_state:
			if (!modification_allowed and has_overlapping_bodies()) or obstructed:
				sprite_2d.self_modulate = Color("df989f")
			else:
				sprite_2d.self_modulate = Globals.block_properties[Globals.current_block_type].colour
		#elif cast_allowed or just_made_action:
			#sprite_2d.self_modulate = Color(1,1,1)
		elif !cast_allowed and !Globals.in_modify_state:
			sprite_2d.self_modulate = Color("df989f")

# Funkcja przyjmująca tablicę obiektów i zwracająca tablicę nazw typów obiektów
func object_to_type(object: Node2D) -> String:
	return object.get_class()

func object_to_name(object: Node2D) -> String:
	return object.name

func check_in_blacklist(object_name: String) -> bool:
	return object_name in blacklist

func change_cursor_color(color: Color = Color("ffffff")) -> void:
	current_cursor_color = color
	sprite_2d.self_modulate = color

func _reset_cursor_color() -> void:
	sprite_2d.self_modulate = current_cursor_color

func _on_timer_timeout() -> void:
	just_made_action = false

func _change_obstructed_state(state: bool) -> void:
	obstructed = state

	if obstructed or obstruction_area.has_overlapping_bodies():
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
	if just_made_action:
		animation_player.play('cast_create')
	else:
		animation_player.play("not_available")
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_UNAVAILABLE)

func _on_block_removed() -> void:
	animation_player.play("cast_remove")
	just_made_action = true
	action_timer.start()

func _play_block_cast() -> void:
	animation_player.play('cast_create')
	just_made_action = true
	action_timer.start()

func _set_initial_values() -> void:
	light_source.texture_scale = 1
	Cursor.light_source.enabled = false
	Cursor.light_source.energy = 0
