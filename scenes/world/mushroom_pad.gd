extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var impulse_force: float = 250

var direction: Vector2

func _ready() -> void:
	direction = -($Sprite2D.global_position - $Marker2D.global_position).normalized()

func apply_velocity_impulse(block: Block, impulse_value: float) -> void:
	block.velocity = Vector2(0,0)
	block.velocity += direction * impulse_value


func _on_body_entered(body: Node2D) -> void:
	if body is Block:
		if "Stone" not in body.current_modifiers:
			apply_velocity_impulse(body, impulse_force)

		animation_player.play("bounce")
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSettings.SoundEffectType.BLOCK_JUMP_PAD)
