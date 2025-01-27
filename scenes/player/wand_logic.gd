extends Node2D

const BLOCK: PackedScene = preload('res://scenes/objects/block.tscn')

@onready var wand_ray_cast: RayCast2D = $WandRayCast

var can_cast: bool = false # Zależne od kolizji obszaru kursora <vvv
var can_modify: bool = false
var received_body: Node2D
var body_type: String = ""

var cast_blocked: bool = false
var remove_blocked: bool = false
var modify_blocked: bool = false

var block_swap_keys: Array = [KEY_1, KEY_2, KEY_3]

func _ready() -> void:
	EventBus.cursor_changed_state.connect(_on_cursor_state_change)

func _input(event: InputEvent) -> void:
	if !Globals.input_enabled or Globals.game_paused or Globals.casting_disabled:
		return

	if event.is_action_pressed('cast') or event.is_action_pressed('cast_destroy'):

		if !wand_ray_cast.raycast_obstruction:

			if event.is_action_pressed('cast'):

				# Block creation functionality
				if can_cast and Globals.block_amount > 0 and !cast_blocked:
					handle_block_creation()

				# Applying modifications functionality
				elif can_modify and Globals.in_modify_state and received_body is Block and !modify_blocked:
					handle_block_modification()

				else:
					EventBus.block_action_rejected.emit()


			# Block destroy and modify removal functionality
			elif event.is_action_pressed('cast_destroy') and !remove_blocked:
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

func handle_block_creation() -> void:
	AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST)
	Globals.block_amount -= 1
	can_cast = false
	EventBus.casted.emit()

func handle_block_modification() -> void:
	var block: Block = received_body
	if block.current_modifiers.size() < block.max_modifier_amount and Globals.current_block_type not in block.current_modifiers:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_APPLY_MOD)
		block.apply_modifier(Globals.current_block_type)
	EventBus.applied_modification.emit(block, Globals.current_block_type)

func handle_block_removal() -> void:
	var block: Block = received_body
	# Destroying block when not in modify state or no modifiers are applied
	if !Globals.in_modify_state: # Removing the block instance
		block.destroy()
		Globals.block_amount += 1
		EventBus.block_removed.emit(block)
	else:
		if !block.current_modifiers.is_empty(): # Removing block's modifier
			block.remove_latest_modifier()
			AudioManager.create_audio(SoundEffectSettings.SoundEffectType.CAST_REMOVE_MOD)
			EventBus.removed_modification.emit(block)
		else: # Removing the block instance
			block.destroy()
			Globals.block_amount += 1
			EventBus.block_removed.emit(block)

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

func _on_wand_ray_cast_spell_blocked(colliding_body: Node) -> void:
	if colliding_body and colliding_body is CastBlocker:
		var cast_blocker: CastBlocker = colliding_body
		cast_blocked = cast_blocker.create_block
		remove_blocked = cast_blocker.remove_block
		modify_blocked = cast_blocker.modify_block
	else:
		cast_blocked = false
		remove_blocked = false
		modify_blocked = false
