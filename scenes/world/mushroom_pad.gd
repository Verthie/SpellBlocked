extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var impulse_force: int = 250

var direction: Vector2

func _ready() -> void:
	direction = -($Sprite2D.global_position - $Marker2D.global_position).normalized()

func apply_velocity_impulse(block: Block) -> void:
	block.velocity = Vector2(0,0)
	block.velocity += direction * impulse_force


func _on_body_entered(body: Node2D) -> void:
	if body is Block:
		if "Stone" not in body.current_modifiers:
			apply_velocity_impulse(body)
		animation_player.play("bounce")
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.BLOCK_JUMP_PAD)
