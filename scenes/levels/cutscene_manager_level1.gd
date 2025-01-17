extends LevelCutscene

@onready var cutscene_player: AnimationPlayer = $CutscenePlayer
@onready var player: Player = $'../Player'

func _ready() -> void:
	EventBus.level_finished.connect(_on_level_finish)

func play_level_enter_cutscene() -> void:
	Globals.playing_cutscene = true
	player.direction = 1.0
	player.animation_player.play("run")
	Globals.playing_cutscene = false

func play_level_exit_cutscene() -> void:
	pass

func _on_level_finish() -> void:
	play_level_exit_cutscene()
