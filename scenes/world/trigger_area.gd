extends Area2D

@onready var pressure_button: StaticBody2D = $'..'
@onready var animation_player: AnimationPlayer = $'../AnimationPlayer'

var blocks_on_button: Array[Block]
var player_on_button: bool = false
var colliding_objects: Array[Node2D]

var block_removed: bool = false

func _ready() -> void:
	EventBus.applied_modification.connect(_on_block_modification_applied)
	EventBus.block_removed.connect(_on_block_removed)
	EventBus.removed_modification.connect(_on_block_modification_removed)
	collision_mask = pressure_button.interactable_entities

func _on_body_entered(body: Node2D) -> void:

	if body is Block:
		blocks_on_button.append(body)

	if body is Player:
		player_on_button = true

	var object_on_button: bool = player_on_button or blocks_on_button.any(func(block: Block) -> bool: return "Stone" in block.current_modifiers)

	if !pressure_button.turned_on and object_on_button:
		trigger_mechanism(true)

func _on_body_exited(body: Node2D) -> void:
	if body is Block:
		blocks_on_button.erase(body)

	if body is Player:
		player_on_button = false
		if !blocks_on_button.any(func(block: Block) -> bool: return "Stone" in block.current_modifiers):
			blocks_on_button.clear()

	var no_object_on_button: bool = !player_on_button and blocks_on_button.is_empty()

	if pressure_button.turned_on and no_object_on_button and !block_removed:
		trigger_mechanism(false)

func trigger_mechanism(state: bool = false) -> void:
	var speed: float = 1 if state else -1
	animation_player.play("press", -1, speed, !state)
	if state:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.BUTTON_PRESS)
	pressure_button.turned_on = state
	for connector: LogicElement in pressure_button.connectors:
		if connector is LogicGate:
			connector.gate_on() if state else connector.gate_off()

func _on_block_modification_applied(block: Block, mod_type: String) -> void:
	if block in blocks_on_button and mod_type == "Stone" and !pressure_button.turned_on:
		trigger_mechanism(true)

func _on_block_removed(block: Block) -> void:
	if block in blocks_on_button:
		blocks_on_button.erase(block)
	if pressure_button.turned_on and (!blocks_on_button.is_empty() or player_on_button):
		block_removed = true
		await get_tree().create_timer(0.3).timeout
		block_removed = false

func _on_block_modification_removed(block: Block) -> void:
	if pressure_button.turned_on and block in blocks_on_button and "Stone" not in block.current_modifiers and !player_on_button:
		trigger_mechanism(false)
