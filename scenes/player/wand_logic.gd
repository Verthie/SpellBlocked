extends Node2D

const BLOCK: PackedScene = preload('res://scenes/objects/block.tscn')

@onready var ray_cast_2d: RayCast2D = $RayCast2D

@export var raycast_enabled: bool = true

#var object_amount: int = 0
var raycast_obstruction: bool = false # Zależne od kolizji raycasta
var can_cast: bool = false # Zależne od kolizji obszaru kursora <vvv
var can_modify: bool = false
var received_body: Node2D
var body_type: String = ""

func _ready() -> void:
	# object_amount = Globals.object_amount #TODO
	Cursor.cursor_changed_state.connect(_on_cursor_state_change)

func _process(_delta: float) -> void:

	handle_sight_obstruction()

	# Block creation functionality
	handle_block_creation()

	# Applying modifications functionality
	handle_block_modification()

	# Block destroy and modify removal functionality
	handle_block_removal()

func handle_sight_obstruction() -> void:
	ray_cast_2d.look_at(get_global_mouse_position())
	ray_cast_2d.target_position.x = get_local_mouse_position().length()

	if raycast_enabled:
		if ray_cast_2d.is_colliding():
			#print("colliding with: ", ray_cast_2d.get_collider())
			raycast_obstruction = true
		else:
			raycast_obstruction = false

		EventBus.obstructed.emit(raycast_obstruction)

func handle_block_creation() -> void:
	if Input.is_action_just_pressed('cast') and !raycast_obstruction and can_cast and Globals.block_amount > 0:
		EventBus.casted.emit()
		AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.CAST)
		Globals.block_amount -= 1
		can_cast = false

func handle_block_modification() -> void:
	if Input.is_action_just_pressed('cast') and !raycast_obstruction and can_modify and Globals.in_modify_state and received_body is Block: # and object_amount > 0 #TODO
		var block: Block = received_body
		block.apply_modifier(Globals.current_block_type)

func handle_block_removal() -> void:
	if Input.is_action_just_pressed('cast_destroy') and !raycast_obstruction and can_modify and received_body is Block:
		var block: Block = received_body
		# Destroying block when not in modify state or no modifiers are applied
		if !Globals.in_modify_state: # Removing block's modifier
			block.destroy()
			AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.CAST_DESTROY)
			Globals.block_amount += 1
		else:
			if !block.current_modifiers.is_empty(): # Removing block's modifier
				block.remove_latest_modifier()
				AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.CAST_REMOVE_MOD)
			else: # Removing the block instance
				block.destroy()
				AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.CAST_DESTROY)
				Globals.block_amount += 1

		# Destroying block only if no modifiers are applied
		#if !block.current_modifiers.is_empty(): # Removing block's modifier
			#block.remove_latest_modifier()
		#else: # Removing the block instance
			#block.destroy()

		can_modify = false

func _on_cursor_state_change(colliding_body: Node, cast_allowed: bool, modification_allowed: bool) -> void:
	received_body = colliding_body
	can_cast = cast_allowed
	can_modify = modification_allowed
