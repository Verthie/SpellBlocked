class_name CutsceneManager
extends  Node2D

@onready var player: Player = $'../Player'

@export var player_enter_duration: float = 1.0
@export var player_enter_length: float = 50.0

func play_level_enter_cutscene() -> void:
	Globals.playing_cutscene = true
	player.global_position.x -= player_enter_length
	var player_x_position: float = player.global_position.x + player_enter_length
	var player_y_position: float = player.global_position.y
	player.animation_player.play("run")
	player.direction = 1.0
	player.call_deferred('set_collisions', true)
	var tween: Tween = create_tween()
	await tween.tween_property(player, 'global_position', Vector2(player_x_position, player_y_position), player_enter_duration).finished
	player.animation_player.play("idle")
	player.call_deferred('set_collisions', false)
	Globals.playing_cutscene = false
