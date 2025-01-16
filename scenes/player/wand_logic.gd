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

var block_swap_keys: Array = [KEY_1, KEY_2, KEY_3]

func _ready() -> void:
	EventBus.cursor_changed_state.connect(_on_cursor_state_change)

func _input(event: InputEvent) -> void:
	if !Globals.input_enabled or Globals.game_paused or Globals.casting_disabled:
		return

	if event.is_action_pressed('cast') or event.is_action_pressed('cast_destroy'):

		if !raycast_obstruction:

			if event.is_action_pressed('cast'):

				# Block creation functionality
				if can_cast and Globals.block_amount > 0:
					handle_block_creation()

				# Applying modifications functionality
				elif can_modify and Globals.in_modify_state and received_body is Block:
					handle_block_modification()

				else:
					EventBus.block_action_rejected.emit()


			# Block destroy and modify removal functionality
			elif event.is_action_pressed('cast_destroy'):
				if can_modify and received_body is Block:
					handle_block_removal()
				else:
					EventBus.block_action_rejected.emit()

		else:
			EventBus.block_action_rejected.emit()

	# Swapping modifier for applying functionality
	if !Globals.modifying_disabled and event is InputEventKey and event.pressed and event.keycode in block_swap_keys:
		#AudioManager.create_audio(SoundEffectSettings.SoundEffectType.MODIFIER_SWAP)

		var allowed_modifiers_amount: int = Globals.allowed_modifiers.size()
		var number_pressed: String = event.as_text()

		if "+" in number_pressed:
			number_pressed = number_pressed.split("+")[1]

		if event.is_action_pressed('switch_' + number_pressed) and allowed_modifiers_amount > (int(number_pressed) - 1):
			Globals.current_block_type = Globals.allowed_modifiers[int(number_pressed) - 1] if Globals.current_block_type != Globals.allowed_modifiers[int(number_pressed) - 1] else "None"

		EventBus.changed_block_type.emit()

func _process(_delta: float) -> void:
	handle_sight_obstruction()

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
	EventBus.casted.emit()
	AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST)
	Globals.block_amount -= 1
	can_cast = false

func handle_block_modification() -> void:
	EventBus.applied_modification.emit()
	var block: Block = received_body
	if block.current_modifiers.size() < block.max_modifier_amount and Globals.current_block_type not in block.current_modifiers:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_APPLY_MOD)
		block.apply_modifier(Globals.current_block_type)

func handle_block_removal() -> void:
	var block: Block = received_body
	# Destroying block when not in modify state or no modifiers are applied
	if !Globals.in_modify_state: # Removing the block instance
		EventBus.block_removed.emit()
		block.destroy()
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_DESTROY)
		Globals.block_amount += 1
	else:
		if !block.current_modifiers.is_empty(): # Removing block's modifier
			EventBus.removed_modification.emit()
			block.remove_latest_modifier()
			AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_REMOVE_MOD)
		else: # Removing the block instance
			EventBus.block_removed.emit()
			block.destroy()
			AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_DESTROY)
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
