extends LevelCutscene

@onready var cutscene_player: AnimationPlayer = $CutscenePlayer
@onready var player: Player = $'../Player'

@export var player_enter_duration: float = 1.0
@export var player_enter_length: int = 50

func _ready() -> void:
	EventBus.level_finished.connect(_on_level_finish)

func play_level_enter_cutscene() -> void:
	Globals.input_enabled = false
	EventBus.cutscene_started.emit()
	player.animation_player.play("run")
	cutscene_player.play("level_start")
	await cutscene_player.animation_finished
	EventBus.cutscene_ended.emit()
	player.animation_player.play("idle")
	await get_tree().create_timer(0.5).timeout
	Globals.input_enabled = true


func play_level_exit_cutscene() -> void:
	pass

func _on_level_finish() -> void:
	play_level_exit_cutscene()
